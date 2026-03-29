# README

### Docker
- docker volume create extra_storage
- docker run --rm -v extra_storage:/data alpine chown -R 1000:1000 /data
- docker build -t cs_contractor .
- docker run -d -p 3000:80 -v extra_storage:/rails/storage --env-file .env --name contractor cs_contractor
#### Import
```bash
/usr/bin/docker run --rm -v extra_storage:/rails/storage --env-file .env cs_contractor bin/rails 'import:prices[true]'
```
