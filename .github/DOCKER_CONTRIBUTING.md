# Contributing to Docker Setup

Thank you for your interest in improving the Docker setup for Marker PDF!

## Quick Start for Contributors

To test Docker changes locally:

```bash
# 1. Make your changes to Dockerfile, docker-compose.yml, etc.

# 2. Build the image
docker build -t marker-pdf:dev .

# 3. Test the image
docker run -p 8000:8000 marker-pdf:dev

# 4. Validate with docker-compose
docker compose config

# 5. Test the full stack
docker compose up -d
curl http://localhost:8000/
docker compose down
```

## Guidelines for Docker Contributions

### Dockerfile Changes

When modifying the Dockerfile:

1. **Keep it minimal**: Only add necessary dependencies
2. **Layer efficiently**: Group related commands to reduce layers
3. **Use caching**: Order instructions from least to most frequently changed
4. **Document changes**: Add comments for non-obvious steps
5. **Test both CPU and GPU**: Ensure changes work in both modes
6. **Verify size**: Check the final image size (`docker images`)

Example good practice:
```dockerfile
# Install system dependencies (changes rarely)
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies (changes occasionally)
RUN poetry install --no-dev

# Copy application code (changes frequently)
COPY . .
```

### docker-compose.yml Changes

When modifying docker-compose.yml:

1. **Validate syntax**: Run `docker compose config` before committing
2. **Document options**: Add comments for non-obvious settings
3. **Test thoroughly**: Ensure `docker compose up` works
4. **Consider compatibility**: Use features supported by Compose V2
5. **Environment variables**: Use `.env.example` as reference

### GitHub Actions Workflow Changes

When modifying `.github/workflows/docker-publish.yml`:

1. **Test in fork**: Push to your fork first to test the workflow
2. **Validate YAML**: Ensure proper syntax
3. **Check permissions**: Verify required permissions are granted
4. **Update documentation**: Document new workflow features
5. **Consider secrets**: Never hardcode secrets in workflow

### Documentation Changes

When updating Docker documentation:

1. **Test commands**: Verify all commands actually work
2. **Update all relevant docs**: Check README.md, README.Docker.md, DOCKER_SETUP.md
3. **Include examples**: Add practical examples for new features
4. **Update version info**: If dependencies change, note version requirements
5. **Proofread**: Check for typos and clarity

## Testing Checklist

Before submitting a PR with Docker changes:

- [ ] Dockerfile builds successfully
- [ ] Container starts without errors
- [ ] Health check passes
- [ ] API is accessible at http://localhost:8000
- [ ] API docs work at http://localhost:8000/docs
- [ ] Test API with a sample PDF
- [ ] docker-compose.yml is valid (`docker compose config`)
- [ ] quick-start.sh runs without errors
- [ ] All documentation is updated
- [ ] No secrets or sensitive data in files
- [ ] .dockerignore is up to date
- [ ] Changes tested on Linux (preferred) or other OS

## Advanced Testing

### Multi-platform Testing

To test on multiple platforms:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t marker-pdf:multi .
```

### Size Optimization Testing

Check image size before and after changes:

```bash
# Before changes
docker images marker-pdf:old

# After changes
docker build -t marker-pdf:new .
docker images marker-pdf:new

# Compare
docker images marker-pdf:* --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

### Performance Testing

Test startup time:

```bash
time docker run --rm marker-pdf:test python -c "from marker.converters.pdf import PdfConverter; print('Ready')"
```

### Security Scanning

Run security scans:

```bash
# Using Docker Scout (if available)
docker scout cves marker-pdf:test

# Using Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image marker-pdf:test
```

## Common Issues and Solutions

### Issue: Image too large

**Solution**: 
- Use `.dockerignore` to exclude unnecessary files
- Use multi-stage builds if possible
- Clean up package manager caches
- Remove build dependencies after use

### Issue: Build fails on ARM

**Solution**:
- Check if all dependencies support ARM64
- Use platform-specific base images if needed
- Test with `--platform linux/arm64`

### Issue: Container crashes on startup

**Solution**:
- Check logs: `docker logs <container-id>`
- Verify environment variables are set correctly
- Ensure all dependencies are installed
- Check file permissions

### Issue: Health check fails

**Solution**:
- Increase `start-period` in HEALTHCHECK
- Verify the server actually starts
- Check if port 8000 is accessible inside container
- Test health check command manually

## Submitting Your Changes

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/improve-docker`
3. **Make your changes**
4. **Test thoroughly** using the checklist above
5. **Commit with clear messages**: `git commit -m "feat(docker): improve build caching"`
6. **Push to your fork**: `git push origin feature/improve-docker`
7. **Open a Pull Request** with:
   - Clear description of changes
   - Why the changes are needed
   - Test results
   - Screenshots if UI changes

## Need Help?

- Check [README.Docker.md](../README.Docker.md) for usage documentation
- Check [DOCKER_SETUP.md](../DOCKER_SETUP.md) for technical details
- Review existing PRs for examples
- Open an issue for discussion before major changes

## Code of Conduct

Please be respectful and constructive in all interactions. We're all here to make this project better!

---

Thank you for contributing to make Marker PDF's Docker setup even better! 🚀
