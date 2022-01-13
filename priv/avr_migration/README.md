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
7. Create AVR collections.
   ```elixir
   AVR.Migration.import_collections()
   ```
8. Link ingested works to their collections.
   ```elixir
   AVR.Migration.map_works_to_collections(ingest_sheet_id)
   ```
9.  Create FileSet objects and link them to their works.
    ```elixir
    AVR.Migration.FileSets.import_filesets(Meadow.Config.ingest_bucket(), Path.join([project.folder, "master_files"]))
    ```
10. Migrate preservation and derivative files and attach them to FileSets.
    ```elixir
    AVR.Migration.FileMover.process_all_file_set_files(project)
    ```
11. While that's running, update work metadata from attached MODS.
    ```
    AVR.Migration.list_avr_works() 
    |> Enum.filter(& &1.descriptive_metadata.title |> is_nil()) 
    |> Repo.preload(:file_sets) 
    |> Task.async_stream(&AVR.Migration.Metadata.update_work_metadata/1, timeout: :infinity) 
    |> Stream.run()
    ```
12. Wait for all files under the S3 project folder to have checksum tags.
13. Iterate over `AVR.Migration.list_avr_filesets()` again and send each FileSet through the
    ingest pipeline.
    ```
    AVR.Migration.Pipeline.submit_batch(1000)
    ```
14. Wait for all the FileSets to make it through the pipeline.
15. Execute the following SQL to correct MIME type misidentification.
    ```
    UPDATE file_sets 
    SET core_metadata = jsonb_set(core_metadata, '{"mime_type"}', '"audio/mp4"')
    FROM works WHERE file_sets.work_id = works.id 
    AND file_sets.accession_number LIKE 'avr:%'
    AND works.work_type->>'id' = 'AUDIO'
    AND file_sets.core_metadata->>'mime_type' LIKE 'video/%';
    ```
16. Generate poster images for the videos.
    ```
    AVR.Migration.avr_filesets_query()
    |> where(fragment("core_metadata->>'mime_type' LIKE 'video/%'"))
    |> where(fragment("derivatives->>'poster' IS NULL"))
    |> Repo.all()
    |> Task.async_stream(& Meadow.Pipeline.Actions.GeneratePosterImage.send_message(%{file_set_id: &1.id}, %{}))
    |> Stream.run()
    ```
17. Set each video work's representative file set to the first one with a poster, if any.
    ```
    AVR.Migration.avr_works_query() |> where(fragment("work_type->>'id' = 'VIDEO'")) |> Repo.all()
    |> Task.async_stream(fn work ->
      case Enum.find(work.file_sets, &(&1.derivatives |> Map.get("poster"))) do
        nil -> work |> Works.update_work(%{representative_file_set_id: nil})
        %{id: file_set_id} -> work |> Works.update_work(%{representative_file_set_id: file_set_id})
      end
    end)
    |> Stream.run()
    ```
18. Do a CSV Metadata Spreadsheet Export of the completed ingest sheet's works.
