# AVR Migration Procedure

1. Download/sync the migration XML and CSV files from `s3://stack-p-avr-masterfiles/meadow-migration/`
   to a local directory.
2. Open a Meadow IEx console with `MEADOW_PROCESSES=none`.
3. Create an AVR Migration project in Meadow.
4. Upload the AVR MODS XML files to the AVR Migration project S3 folder and wait a few
   minutes for all the digest tags to populate. **Note:** If running this in the dev environment,
   try to upload things in smaller chunks, like one subdirectory at a time with a few seconds'
   pause in between. The `minio-checksum` container has trouble keeping up under heavy load.
5. Ingest `avr_migration.csv` into the AVR Migration project. It should take about 2 minutes to 
   validate and 20 to ingest.
6. Copy the ID of the completed ingest sheet.
7. Load the migration module.
   ```elixir
   iex> Code.compile_file("priv/avr_migration/avr_migration.exs")
   ```
8. Create AVR collections.
   ```elixir
   iex> AVR.Migration.import_collections()
   ```
9. Link ingested works to their collections.
   ```elixir
   iex> AVR.Migration.map_works_to_collections(ingest_sheet_id)
   ```
10. Create AVR Subject Headings.
    ```elixir
    iex> AVR.Migration.import_subjects()
    ```
11. Create FileSet objects and link them to their works.
    ```elixir
    iex> AVR.Migration.import_filesets(ingest_bucket, Path.join([project_folder, "master_files"])
    ```
12. Do a CSV Metadata Spreadsheet Export of the completed ingest sheet's works.

# MasterFile/Derivative moves

1. Create FileSet objects with accession numbers `"avr:#{masterfile_id}`
2. 