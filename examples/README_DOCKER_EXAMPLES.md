# Docker API Usage Examples

This directory contains examples for using the Marker API server when deployed with Docker.

## Prerequisites

Make sure the Marker server is running:

```bash
# Using quick start script
./quick-start.sh

# OR using docker compose
docker compose up -d

# OR using pre-built image
docker run -d -p 8000:8000 --name marker-server ghcr.io/gentle-lijie/marker-docker:latest
```

Verify the server is running:

```bash
curl http://localhost:8000/
```

## Python Example

### Using the Test Script

We provide a convenient test script that handles file upload and conversion:

```bash
# Install dependencies
pip install requests Pillow

# Convert a PDF to markdown
python examples/test_api.py path/to/your/document.pdf

# Convert to JSON
python examples/test_api.py path/to/your/document.pdf json

# Convert to HTML
python examples/test_api.py path/to/your/document.pdf html
```

### Custom Python Script

```python
import requests

# Upload and convert a PDF
with open("document.pdf", "rb") as f:
    files = {"file": ("document.pdf", f, "application/pdf")}
    data = {
        "output_format": "markdown",
        "force_ocr": False,
        "paginate_output": False,
    }
    
    response = requests.post(
        "http://localhost:8000/marker/upload",
        files=files,
        data=data
    )
    
    result = response.json()
    if result["success"]:
        print(result["output"])  # The converted markdown
        print(result["metadata"])  # Document metadata
    else:
        print(f"Error: {result['error']}")
```

## Curl Examples

### Upload and Convert

```bash
# Convert to markdown
curl -X POST "http://localhost:8000/marker/upload" \
  -F "file=@document.pdf" \
  -F "output_format=markdown"

# Convert to JSON with OCR
curl -X POST "http://localhost:8000/marker/upload" \
  -F "file=@document.pdf" \
  -F "output_format=json" \
  -F "force_ocr=true"

# Convert specific pages
curl -X POST "http://localhost:8000/marker/upload" \
  -F "file=@document.pdf" \
  -F "output_format=markdown" \
  -F "page_range=0,5-10,20"
```

### Convert File on Server

If you have mounted a volume with PDFs:

```bash
curl -X POST "http://localhost:8000/marker" \
  -H "Content-Type: application/json" \
  -d '{
    "filepath": "/app/uploads/document.pdf",
    "output_format": "markdown"
  }'
```

## JavaScript/Node.js Example

```javascript
const FormData = require('form-data');
const fs = require('fs');
const axios = require('axios');

async function convertPDF(filePath) {
    const formData = new FormData();
    formData.append('file', fs.createReadStream(filePath));
    formData.append('output_format', 'markdown');
    formData.append('force_ocr', 'false');
    
    try {
        const response = await axios.post(
            'http://localhost:8000/marker/upload',
            formData,
            {
                headers: formData.getHeaders(),
                maxBodyLength: Infinity,
                maxContentLength: Infinity
            }
        );
        
        if (response.data.success) {
            console.log('Conversion successful!');
            console.log(response.data.output);
        } else {
            console.error('Conversion failed:', response.data.error);
        }
    } catch (error) {
        console.error('Error:', error.message);
    }
}

convertPDF('document.pdf');
```

## Output Formats

### Markdown (default)

Returns formatted markdown with:
- Image links (images in base64)
- Formatted tables
- LaTeX equations
- Code blocks

```bash
curl -X POST "http://localhost:8000/marker/upload" \
  -F "file=@document.pdf" \
  -F "output_format=markdown"
```

### JSON

Returns structured JSON with:
- Hierarchical document structure
- Block types (text, table, image, etc.)
- Bounding boxes for each element
- Metadata

```bash
curl -X POST "http://localhost:8000/marker/upload" \
  -F "file=@document.pdf" \
  -F "output_format=json"
```

### HTML

Returns HTML representation:
- Images as `<img>` tags
- Equations in `<math>` tags
- Code in `<pre>` tags

```bash
curl -X POST "http://localhost:8000/marker/upload" \
  -F "file=@document.pdf" \
  -F "output_format=html"
```

### Chunks

Returns flattened list of blocks for RAG:
- Top-level blocks from each page
- Full HTML content embedded
- Easy to chunk for vector databases

```bash
curl -X POST "http://localhost:8000/marker/upload" \
  -F "file=@document.pdf" \
  -F "output_format=chunks"
```

## Advanced Options

### Force OCR

Force optical character recognition on all pages:

```bash
curl -X POST "http://localhost:8000/marker/upload" \
  -F "file=@document.pdf" \
  -F "force_ocr=true"
```

### Page Range

Convert specific pages only:

```bash
curl -X POST "http://localhost:8000/marker/upload" \
  -F "file=@document.pdf" \
  -F "page_range=0,5-10,20"
```

### Paginate Output

Add page separators in the output:

```bash
curl -X POST "http://localhost:8000/marker/upload" \
  -F "file=@document.pdf" \
  -F "paginate_output=true"
```

## Response Format

All API responses follow this format:

```json
{
  "success": true,
  "format": "markdown",
  "output": "# Document content...",
  "images": {
    "image_1": "base64_encoded_image_data..."
  },
  "metadata": {
    "table_of_contents": [...],
    "page_stats": [...]
  }
}
```

Error response:

```json
{
  "success": false,
  "error": "Error message describing what went wrong"
}
```

## Interactive API Documentation

Visit `http://localhost:8000/docs` for interactive Swagger UI documentation where you can:
- Try out API endpoints directly from your browser
- See detailed parameter descriptions
- View example requests and responses

## Troubleshooting

### Connection Refused

If you get "Connection refused" error:

```bash
# Check if container is running
docker ps | grep marker-server

# Check container logs
docker logs marker-server

# Restart the container
docker restart marker-server
```

### Large Files

For large PDF files, you may need to increase timeout:

```python
response = requests.post(
    "http://localhost:8000/marker/upload",
    files=files,
    data=data,
    timeout=600  # 10 minutes
)
```

### Memory Issues

If the server runs out of memory:

```bash
# Increase Docker memory limit or convert fewer pages
curl -X POST "http://localhost:8000/marker/upload" \
  -F "file=@large_document.pdf" \
  -F "page_range=0-10"  # Convert first 11 pages only
```
