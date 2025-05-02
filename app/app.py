from flask import Flask
import torch

app = Flask(__name__)

# Define a route for the root URL
@app.route('/')
def home():
    return f"{torch.cuda.is_available()}, Hello, Flask!"

# Run the server
if __name__ == '__main__':
    app.run(debug=True)
