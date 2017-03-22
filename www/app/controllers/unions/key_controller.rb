class Unions::KeyController < ApplicationController
  # this is pretty dreadful
  before_action :set_key

  def show
    redirect_to new_union_key_path(@union) unless @union.key_pair.present?
  end

  def update
    respond_to do |format|
      @union.assign_attributes(key_params)
      #if @union.update(key_params)
      if @union.save
        format.html { redirect_to union_key_path(@union), notice: "Encryption key was successfully updated." }
      else
        format.html { render :edit }
      end
    end
   end

   def set_key
     @key = @union.key_pair
   end

   def key_params
     params.require(:union).permit(:old_passphrase, :passphrase, :passphrase_confirmation)
   end
end
