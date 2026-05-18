# README

### Docker
- docker volume create extra_storage
- docker run --rm -v extra_storage:/data alpine chown -R 1000:1000 /data
- docker build -t cs_contractor .
- docker run -d -p 3000:80 -v extra_storage:/rails/storage --env-file .env --name contractor cs_contractor
#### Import
```bash
docker run --rm -v extra_storage:/rails/storage --env-file /Users/denys.taradada/Projects/pet_and_testing/cs_contractor/.env cs_contractor bin/rails 'import:prices[true]'
```
