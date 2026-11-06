# Audit record for a "deleted" (hidden) PDF.
# The file itself is NOT deleted: its attachment is moved from
# lawsuit.pdf_files to lawsuit.deleted_pdf_files. Restoring removes this record.
class CreatePdfFileDeletions < ActiveRecord::Migration[7.2]
  def change
    create_table :pdf_file_deletions do |t|
      t.references :lawsuit, null: false, foreign_key: true
      t.references :attachment, null: false, index: { unique: true },
                   foreign_key: { to_table: :active_storage_attachments }
      t.references :deleted_by_user, null: false, foreign_key: { to_table: :users }
      t.text :reason, null: false
      t.timestamps
    end
  end
end
