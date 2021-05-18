defmodule Meadow.Repo.Migrations.ConvertExifToExtractedMetadata do
  use Ecto.Migration

  def up do
    execute """
    UPDATE file_sets
    SET metadata = jsonb_set(metadata, '{extracted_metadata}', 'null') - 'exif'
    WHERE metadata->>'exif' IS NULL;
    """

    execute """
    UPDATE file_sets
    SET metadata = jsonb_set(jsonb_set(metadata, '{extracted_metadata}', '{"exif": {"tool": "exifr", "tool_version": "6.1.1"}}'), '{extracted_metadata,exif,value}', metadata->'exif') - 'exif'
    WHERE metadata->>'exif' IS NOT NULL;
    """
  end

  def down do
    execute """
    UPDATE file_sets
    SET metadata = jsonb_set(metadata, '{exif}', 'null') - 'extracted_metadata'
    WHERE metadata->>'extracted_metadata' IS NULL
      OR metadata->'extracted_metadata'->>'exif' IS NULL
      OR metadata->'extracted_metadata'->'exif'->>'value' IS NULL;
    """

    execute """
    UPDATE file_sets
    SET metadata = jsonb_set(metadata, '{exif}', metadata->'extracted_metadata'->'exif'->'value') - 'extracted_metadata'
    WHERE metadata->>'extracted_metadata' IS NOT NULL
      AND metadata->'extracted_metadata'->>'exif' IS NOT NULL
      AND metadata->'extracted_metadata'->'exif'->>'value' IS NOT NULL;
    """
  end
end
