# AVR Migration Procedure

1. Download/sync the migration XML and CSV files from `s3://stack-p-avr-masterfiles/meadow-migration/`
    to a local directory.
2. Open a Meadow IEx console with `MEADOW_PROCESSES=none`.
3. Load the migration module.
   ```elixir
   iex> Code.compile_file("priv/avr_migration/avr_migration.exs")
   ```
4. Create AVR collections.
   ```elixir
   iex> AVR.Migration.import_collections()
   ```
5. Create an AVR Migration project in Meadow.
6. Upload the AVR MODS XML files to the AVR Migration project S3 folder and wait a few
    minutes for all the digest tags to populate.
7. Ingest `avr_migration.csv` into the AVR Migration project. It should take about 2 minutes to validate and 20 to ingest.
8. Copy the ID of the completed ingest sheet.
9. Link ingested works to their collections.
   ```elixir
   iex> AVR.Migration.map_works_to_collections(ingest_sheet_id)
   ```
