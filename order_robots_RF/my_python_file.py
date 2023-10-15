from PIL import Image
from typing import Tuple

def resize_image(input_image_path: str, output_image_path: str, size: Tuple[int, int]) -> None:
    original_image = Image.open(input_image_path)
    resized_image = original_image.resize(size)
    resized_image.save(output_image_path)