from PIL import Image
import os

def add_padding(input_path, output_path, padding_percent=0.25):
    """
    Adds transparent padding around the image.
    padding_percent: The percentage of the target image size that should be padding.
    """
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found")
        return

    # Open the original image
    img = Image.open(input_path).convert("RGBA")
    width, height = img.size
    
    # Calculate the largest dimension to maintain aspect ratio
    max_dim = max(width, height)
    
    # We want the original image to occupy (1 - padding_percent*2) of the new size
    # Let's target a 1024x1024 final size for high quality
    target_size = 1024
    
    # Scale factor for the internal content
    # For adaptive icons, the safe zone is roughly 66% of the 108dp icon.
    # So we want the content to be around 60-70% of the total size.
    content_scale = 1.0 - (padding_percent * 2)
    new_content_size = int(target_size * content_scale)
    
    # Resize the original image relative to the target size while maintaining aspect ratio
    aspect_ratio = width / height
    if aspect_ratio > 1:
        # Wider than tall
        resize_width = new_content_size
        resize_height = int(new_content_size / aspect_ratio)
    else:
        # Taller than wide
        resize_height = new_content_size
        resize_width = int(new_content_size * aspect_ratio)
        
    img_resized = img.resize((resize_width, resize_height), Image.Resampling.LANCZOS)
    
    # Create a new transparent image
    new_img = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    
    # Paste the resized image into the center
    paste_x = (target_size - resize_width) // 2
    paste_y = (target_size - resize_height) // 2
    
    new_img.alpha_composite(img_resized, (paste_x, paste_y))
    
    # Save the result
    new_img.save(output_path)
    print(f"Success! Padded logo saved to {output_path} (Final size: {target_size}x{target_size})")

if __name__ == "__main__":
    input_file = r"assets/images/SpaceEscaperLogo.png"
    output_file = r"assets/images/SpaceEscaperLogo_padded.png"
    add_padding(input_file, output_file)
