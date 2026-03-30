import sys
from PIL import Image, ImageFilter
import pytesseract

def main():
    if len(sys.argv) < 3:
        print("Usage: python distort_ocr.py <image_path> <target_text>")
        sys.exit(1)

    image_path = sys.argv[1]
    target_text = sys.argv[2]
    
    img = Image.open(image_path)
    # Get verbose OCR data including coordinates
    data = pytesseract.image_to_data(img, output_type=pytesseract.Output.DICT)

    found = False
    for i, text in enumerate(data['text']):
        if target_text.lower() in text.lower() and text.strip():
            # Extract bounding box
            x, y, w, h = data['left'][i], data['top'][i], data['width'][i], data['height'][i]
            coords = (x, y, x + w, y + h)
            
            # Apply distortion
            region = img.crop(coords)
            distorted = region.filter(ImageFilter.GaussianBlur(radius=15))
            img.paste(distorted, coords)
            found = True

    if found:
        output_name = f"distorted_{image_path}"
        img.save(output_name)
        print(f"Success: Processed image saved as {output_name}")
    else:
        print(f"Error: Text '{target_text}' not detected in image.")

if __name__ == "__main__":
    main()