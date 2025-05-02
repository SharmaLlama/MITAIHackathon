import os
import torch
from torch.utils.data import Dataset, DataLoader
from pycocotools.coco import COCO
import numpy as np
from PIL import Image
import albumentations as A
from albumentations.pytorch import ToTensorV2
import cv2

class COCOBoundingBoxDataset(Dataset):
    def __init__(self, img_dir, ann_file, transforms=None, category_ids=None):
        self.img_dir = img_dir
        self.coco = COCO(ann_file)
        self.transforms = transforms
        
        # Filter by category_ids if provided
        if category_ids is not None:
            self.ids = []
            for cat_id in category_ids:
                self.ids.extend(self.coco.getImgIds(catIds=[cat_id]))
            # Remove duplicates
            self.ids = list(set(self.ids))
        else:
            # Get all image ids
            self.ids = self.coco.getImgIds()
            
        # Get all categories and create a mapping
        self.categories = self.coco.loadCats(self.coco.getCatIds())
        self.cat_id_to_idx = {cat['id']: idx for idx, cat in enumerate(self.categories)}
        
    def __len__(self):
        return len(self.ids)
    
    def __getitem__(self, index):
        img_id = self.ids[index]
        img_info = self.coco.loadImgs(img_id)[0]
        img_path = os.path.join(self.img_dir, img_info['file_name'])
        
        image = cv2.imread(img_path)
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        ann_ids = self.coco.getAnnIds(imgIds=img_id)
        anns = self.coco.loadAnns(ann_ids)
        
        # Get bounding boxes and labels
        bboxes = []
        labels = []
        areas = []
        iscrowd = []
        
        for ann in anns:
            # Skip annotations with no bbox
            if 'bbox' not in ann:
                continue
                
            # Keep bboxes in COCO format [x, y, width, height] for Albumentations
            x, y, w, h = ann['bbox']
            
            if w <= 0 or h <= 0:
                continue
                
            # Get category index
            cat_id = ann['category_id']
            if cat_id in self.cat_id_to_idx:
                cat_idx = self.cat_id_to_idx[cat_id]
            else:
                continue  # Skip categories not in our mapping
                
            # Add to lists - keep as COCO format for Albumentations
            bboxes.append([x, y, w, h])
            labels.append(cat_idx)
            areas.append(ann.get('area', w * h))
            iscrowd.append(ann.get('iscrowd', 0))
        
        # Apply Albumentations transforms
        if self.transforms:
            transformed = self.transforms(
                image=image,
                bboxes=bboxes,
                labels=labels
            )
            image = transformed['image']
            bboxes = transformed['bboxes']
            labels = transformed['labels']
        
        boxes_pytorch = []
        for bbox in bboxes:
            x, y, w, h = bbox
            boxes_pytorch.append([x, y, x + w, y + h])
            
        target = {}
        target['boxes'] = torch.as_tensor(boxes_pytorch, dtype=torch.float32)
        target['labels'] = torch.as_tensor(labels, dtype=torch.int64)
        target['image_id'] = torch.tensor([img_id])
        target['area'] = torch.as_tensor(areas, dtype=torch.float32)[:len(bboxes)]
        target['iscrowd'] = torch.as_tensor(iscrowd, dtype=torch.int64)[:len(bboxes)]
        
        return image, target


def create_coco_data_loader(img_dir, ann_file, batch_size=2, shuffle=True, num_workers=4):
    transform = A.Compose([
        A.RandomSizedBBoxSafeCrop(height=800, width=800, erosion_rate=0.2),
        A.HorizontalFlip(p=0.5),
        A.Affine(
            scale=(0.8, 1.2),
            translate_percent=(-0.2, 0.2),
            rotate=(-15, 15),
            shear=(-10, 10),
            p=0.7
        ),
        A.OneOf([
            A.RandomBrightnessContrast(p=1),
            A.RandomGamma(p=1),
            A.HueSaturationValue(p=1)
        ], p=0.7),
        A.OneOf([
            A.GaussNoise(p=1),
            A.GaussianBlur(blur_limit=(3, 7), p=1),
            A.MotionBlur(blur_limit=(3, 7), p=1)
        ], p=0.5),
        A.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        A.ToTensorV2(),
    ], bbox_params=A.BboxParams(
        format='coco',  # COCO format: [x, y, width, height]
        label_fields=['labels'],
    ))
    
    # Create dataset
    dataset = COCOBoundingBoxDataset(
        img_dir=img_dir,
        ann_file=ann_file,
        transforms=transform,
    )
    
    def collate_fn(batch):
        images = []
        targets = []
        for img, target in batch:
            images.append(img)
            targets.append(target)
        
        return torch.stack(images), targets
    
    # Create dataloader
    data_loader = DataLoader(
        dataset,
        batch_size=batch_size,
        shuffle=shuffle,
        num_workers=num_workers,
        collate_fn=collate_fn
    )
    
    return data_loader