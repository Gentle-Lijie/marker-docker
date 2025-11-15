#!/usr/bin/env python3
"""
Example script to test the Marker API server.

Usage:
    python test_api.py <path_to_pdf>

Requirements:
    pip install requests
"""

import sys
import requests
import json
from pathlib import Path


def test_health_check(base_url="http://localhost:8000"):
    """Test if the server is running."""
    print("🔍 Checking server health...")
    try:
        response = requests.get(base_url, timeout=5)
        if response.status_code == 200:
            print("✅ Server is running!")
            return True
        else:
            print(f"❌ Server returned status code: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Server is not reachable: {e}")
        return False


def convert_pdf(pdf_path, output_format="markdown", base_url="http://localhost:8000"):
    """
    Convert a PDF file using the Marker API.
    
    Args:
        pdf_path: Path to the PDF file
        output_format: Output format (markdown, json, html, chunks)
        base_url: Base URL of the API server
    
    Returns:
        Response data as dictionary
    """
    pdf_path = Path(pdf_path)
    
    if not pdf_path.exists():
        print(f"❌ File not found: {pdf_path}")
        return None
    
    print(f"📄 Converting: {pdf_path.name}")
    print(f"   Format: {output_format}")
    
    with open(pdf_path, "rb") as f:
        files = {"file": (pdf_path.name, f, "application/pdf")}
        data = {
            "output_format": output_format,
            "force_ocr": False,
            "paginate_output": False,
        }
        
        try:
            print("⏳ Uploading and converting (this may take a moment)...")
            response = requests.post(
                f"{base_url}/marker/upload",
                files=files,
                data=data,
                timeout=300  # 5 minutes timeout for large files
            )
            
            if response.status_code == 200:
                result = response.json()
                if result.get("success"):
                    print("✅ Conversion successful!")
                    return result
                else:
                    print(f"❌ Conversion failed: {result.get('error', 'Unknown error')}")
                    return None
            else:
                print(f"❌ Request failed with status code: {response.status_code}")
                print(f"   Response: {response.text[:200]}")
                return None
                
        except requests.exceptions.Timeout:
            print("❌ Request timed out. The file may be too large or the server is busy.")
            return None
        except requests.exceptions.RequestException as e:
            print(f"❌ Request failed: {e}")
            return None


def save_output(result, output_path):
    """Save the conversion output to a file."""
    if not result:
        return
    
    output_path = Path(output_path)
    
    # Save the main output
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(result["output"])
    print(f"💾 Output saved to: {output_path}")
    
    # Save metadata
    metadata_path = output_path.with_suffix(".metadata.json")
    with open(metadata_path, "w", encoding="utf-8") as f:
        json.dump(result["metadata"], f, indent=2)
    print(f"💾 Metadata saved to: {metadata_path}")
    
    # Save images if present
    if result.get("images"):
        import base64
        from PIL import Image
        from io import BytesIO
        
        images_dir = output_path.parent / f"{output_path.stem}_images"
        images_dir.mkdir(exist_ok=True)
        
        print(f"🖼️  Saving {len(result['images'])} images...")
        for img_name, img_data in result["images"].items():
            img_bytes = base64.b64decode(img_data)
            img = Image.open(BytesIO(img_bytes))
            img_path = images_dir / f"{img_name}.png"
            img.save(img_path)
        print(f"💾 Images saved to: {images_dir}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python test_api.py <path_to_pdf> [output_format]")
        print("Output formats: markdown (default), json, html, chunks")
        sys.exit(1)
    
    pdf_path = sys.argv[1]
    output_format = sys.argv[2] if len(sys.argv) > 2 else "markdown"
    
    # Test server health
    if not test_health_check():
        print("\n❌ Please make sure the Marker server is running:")
        print("   docker compose up -d")
        print("   OR")
        print("   ./quick-start.sh")
        sys.exit(1)
    
    print()
    
    # Convert PDF
    result = convert_pdf(pdf_path, output_format)
    
    if result:
        # Save output
        pdf_path = Path(pdf_path)
        output_ext = {
            "markdown": ".md",
            "json": ".json",
            "html": ".html",
            "chunks": ".chunks.json"
        }.get(output_format, ".txt")
        
        output_path = pdf_path.with_suffix(output_ext)
        save_output(result, output_path)
        
        print("\n✨ Done! You can now view your converted file.")
    else:
        print("\n❌ Conversion failed. Please check the error messages above.")
        sys.exit(1)


if __name__ == "__main__":
    main()
