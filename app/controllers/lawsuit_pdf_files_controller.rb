# Delete (hide) and restore PDFs of a lawsuit. Nothing is physically deleted.
class LawsuitPdfFilesController < ApplicationController
  before_action :set_lawsuit

  def destroy
    authorize @lawsuit, :destroy_pdf?
    attachment = @lawsuit.pdf_files_attachments.find(params[:id])

    reason = params[:deletion_reason].to_s.strip
    if reason.blank?
      return redirect_to lawsuit_edit_page, alert: "Arsyeja e fshirjes është e detyrueshme."
    end

    @lawsuit.hide_pdf!(attachment, user: current_user, reason: reason)
    # Deleting happens in "Ndrysho", so go back there
    redirect_to lawsuit_edit_page, notice: "Dokumenti \"#{attachment.filename}\" u fshi."
  end

  def restore
    authorize @lawsuit, :restore_pdf?
    attachment = @lawsuit.deleted_pdf_files_attachments.find(params[:id])

    @lawsuit.restore_pdf!(attachment)
    redirect_to lawsuit_page, notice: "Dokumenti \"#{attachment.filename}\" u rikthye."
  end

  private

  def set_lawsuit
    @lawsuit = Lawsuit.kept.find(params[:lawsuit_id])
  end

  def lawsuit_page
    show_lawsuits_path(category: @lawsuit.category, id: @lawsuit.id)
  end

  def lawsuit_edit_page
    edit_lawsuits_path(category: @lawsuit.category, id: @lawsuit.id)
  end
end
