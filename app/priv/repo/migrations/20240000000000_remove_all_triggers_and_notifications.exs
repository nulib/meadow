defmodule Meadow.Repo.Migrations.RemoveAllTriggersAndNotifications do
  use Ecto.Migration

  def up do
    # Drop all notification and reindex triggers
    execute "DROP TRIGGER IF EXISTS collections_works_reindex_delete ON collections"
    execute "DROP TRIGGER IF EXISTS collections_works_reindex_insert ON collections"
    execute "DROP TRIGGER IF EXISTS collections_works_reindex_update ON collections"
    execute "DROP TRIGGER IF EXISTS file_sets_deleted ON file_sets"
    execute "DROP TRIGGER IF EXISTS file_sets_works_reindex_delete ON file_sets"
    execute "DROP TRIGGER IF EXISTS file_sets_works_reindex_insert ON file_sets"
    execute "DROP TRIGGER IF EXISTS file_sets_works_reindex_update ON file_sets"
    execute "DROP TRIGGER IF EXISTS ingest_sheets_works_reindex_delete ON ingest_sheets"
    execute "DROP TRIGGER IF EXISTS ingest_sheets_works_reindex_insert ON ingest_sheets"
    execute "DROP TRIGGER IF EXISTS ingest_sheets_works_reindex_update ON ingest_sheets"

    execute "DROP TRIGGER IF EXISTS notify_collections_when_collections_changes_delete ON collections"

    execute "DROP TRIGGER IF EXISTS notify_collections_when_collections_changes_insert ON collections"

    execute "DROP TRIGGER IF EXISTS notify_collections_when_collections_changes_update ON collections"

    execute "DROP TRIGGER IF EXISTS notify_file_sets_when_file_sets_changes_delete ON file_sets"
    execute "DROP TRIGGER IF EXISTS notify_file_sets_when_file_sets_changes_insert ON file_sets"
    execute "DROP TRIGGER IF EXISTS notify_file_sets_when_file_sets_changes_update ON file_sets"
    execute "DROP TRIGGER IF EXISTS notify_ingest_sheets_when_ingest_sheets_changes_delete ON ingest_sheets"
    execute "DROP TRIGGER IF EXISTS notify_ingest_sheets_when_ingest_sheets_changes_insert ON ingest_sheets"
    execute "DROP TRIGGER IF EXISTS notify_ingest_sheets_when_ingest_sheets_changes_update ON ingest_sheets"
    execute "DROP TRIGGER IF EXISTS notify_works_when_file_sets_changes_delete ON file_sets"
    execute "DROP TRIGGER IF EXISTS notify_works_when_file_sets_changes_insert ON file_sets"
    execute "DROP TRIGGER IF EXISTS notify_works_when_file_sets_changes_update ON file_sets"
    execute "DROP TRIGGER IF EXISTS notify_works_when_works_changes_delete ON works"
    execute "DROP TRIGGER IF EXISTS notify_works_when_works_changes_insert ON works"
    execute "DROP TRIGGER IF EXISTS notify_works_when_works_changes_update ON works"
    execute "DROP TRIGGER IF EXISTS projects_work_reindex ON works"
    execute "DROP TRIGGER IF EXISTS works_collections_reindex_delete ON works"
    execute "DROP TRIGGER IF EXISTS works_collections_reindex_insert ON works"
    execute "DROP TRIGGER IF EXISTS works_collections_reindex_update ON works"
    execute "DROP TRIGGER IF EXISTS works_file_sets_reindex_delete ON works"
    execute "DROP TRIGGER IF EXISTS works_file_sets_reindex_insert ON works"
    execute "DROP TRIGGER IF EXISTS works_file_sets_reindex_update ON works"

    # Drop notification functions
    execute "DROP FUNCTION IF EXISTS notify_collections CASCADE"
    execute "DROP FUNCTION IF EXISTS notify_collections_when_collections_changes CASCADE"
    execute "DROP FUNCTION IF EXISTS notify_file_sets CASCADE"
    execute "DROP FUNCTION IF EXISTS notify_file_sets_deleted CASCADE"
    execute "DROP FUNCTION IF EXISTS notify_file_sets_when_file_sets_changes CASCADE"
    execute "DROP FUNCTION IF EXISTS notify_ingest_sheets CASCADE"
    execute "DROP FUNCTION IF EXISTS notify_ingest_sheets_when_ingest_sheets_changes CASCADE"
    execute "DROP FUNCTION IF EXISTS notify_works CASCADE"
    execute "DROP FUNCTION IF EXISTS notify_works_when_file_sets_changes CASCADE"
    execute "DROP FUNCTION IF EXISTS notify_works_when_works_changes CASCADE"
    execute "DROP FUNCTION IF EXISTS reindex_collections_when_works_changes CASCADE"
    execute "DROP FUNCTION IF EXISTS reindex_file_sets_when_works_changes CASCADE"
    execute "DROP FUNCTION IF EXISTS reindex_work_when_project_changes CASCADE"
    execute "DROP FUNCTION IF EXISTS reindex_works_when_collections_changes CASCADE"
    execute "DROP FUNCTION IF EXISTS reindex_works_when_file_sets_changes CASCADE"
    execute "DROP FUNCTION IF EXISTS reindex_works_when_ingest_sheets_changes CASCADE"
    execute "DROP FUNCTION IF EXISTS update_work_when_collection_changes CASCADE"
    execute "DROP FUNCTION IF EXISTS update_work_when_file_set_changes CASCADE"
    execute "DROP FUNCTION IF EXISTS update_work_when_ingest_sheet_changes CASCADE"
  end

  def down do
    raise "This migration cannot be reversed"
  end
end
