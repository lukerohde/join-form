class UpdateOrganiserIdOnJoinForm < ActiveRecord::Migration
	def up
  	execute "update join_forms set organiser_id = (select id from people where email like 'jbreen%' limit 1)"
  end

  def down
  end
end
