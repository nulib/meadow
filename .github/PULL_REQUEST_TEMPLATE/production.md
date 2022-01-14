## :rocket: Production Deployment Checklist

- [ ] Version bump
- [ ] Terraform changes required
  - [ ] Terraform changes already applied?
  - [ ] Terraform changes to be applied during deploy after merge?
- [ ] Notable API changes? (GraphQL, db, ingest sheet, etc.)
- [ ] New/Updated Environment Variables set
- [ ] Check for data migrations
- [ ] Check for database schema changes
- [ ] Reindex required?
- [ ] New external dependencies (include any sychronization instructions)
- [ ] Release tagged?
- [ ] Service manager notified with release information including changelog

## :rotating_light: Production data changes

:warning: These items assuming this deploy applies data migrations that will affect many rows:

- [ ] Determine which triggers or notifications need to be disabled if any
- [ ] Manual database snapshot required?
- [ ] Manual Elasticsearch snapshot required?

## :open_book: Changelog

- first item
- second item