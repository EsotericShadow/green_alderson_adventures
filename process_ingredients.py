#!/usr/bin/env python3
"""Convert JPG ingredient images to PNG with background removal."""

import os
from PIL import Image
import sys

def remove_background_simple(img):
    """Simple background removal - makes white/very light pixels transparent."""
    img = img.convert("RGBA")
    data = img.getdata()
    
    new_data = []
    for item in data:
        # If pixel is white or very light (RGB all > 240), make transparent
        if item[0] > 240 and item[1] > 240 and item[2] > 240:
            new_data.append((255, 255, 255, 0))  # Transparent
        else:
            new_data.append(item)
    
    img.putdata(new_data)
    return img

def process_image(input_path, output_path):
    """Process a single image: load JPG, remove background, save as PNG."""
    try:
        # Load image
        img = Image.open(input_path)
        
        # Remove background
        img = remove_background_simple(img)
        
        # Save as PNG
        img.save(output_path, "PNG")
        print(f"✓ Processed: {os.path.basename(input_path)} -> {os.path.basename(output_path)}")
        return True
    except Exception as e:
        print(f"✗ Error processing {input_path}: {e}")
        return False

def main():
    ingredients_dir = "resources/assets/ingredients"
    
    if not os.path.exists(ingredients_dir):
        print(f"Error: Directory {ingredients_dir} not found")
        sys.exit(1)
    
    jpg_files = [f for f in os.listdir(ingredients_dir) if f.endswith('.jpg')]
    
    if not jpg_files:
        print(f"No JPG files found in {ingredients_dir}")
        sys.exit(1)
    
    print(f"Processing {len(jpg_files)} images...")
    
    success_count = 0
    for jpg_file in jpg_files:
        input_path = os.path.join(ingredients_dir, jpg_file)
        png_file = jpg_file.replace('.jpg', '.png')
        output_path = os.path.join(ingredients_dir, png_file)
        
        if process_image(input_path, output_path):
            success_count += 1
    
    print(f"\n✓ Successfully processed {success_count}/{len(jpg_files)} images")
    print(f"PNG files saved to: {ingredients_dir}")

if __name__ == "__main__":
    main()

