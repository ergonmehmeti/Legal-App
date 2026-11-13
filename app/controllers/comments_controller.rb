class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    # Only on a lawsuit the user can see (policy_scope), and only roles that may comment
    lawsuit = policy_scope(Lawsuit).kept.find_by(id: comment_params[:lawsuit_id])
    return redirect_to(root_path, alert: "Lënda nuk u gjet.") unless lawsuit
    authorize lawsuit, :comment?

    @comment = Comment.new(comment_params)
    @comment.user_id = current_user.id if user_signed_in?
    if @comment.save
      redirect_to show_lawsuits_path(category: @comment.lawsuit.category, id: @comment.lawsuit_id)
    end
  end


  private
  def comment_params
    params.require(:comment).permit(:content, :lawsuit_id)

  end
end
