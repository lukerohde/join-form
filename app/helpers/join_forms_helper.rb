module JoinFormsHelper
	
	def message_types_options
		options_for_select(
				(%w[
						blast_email.created
						category.created
						category.updated
						data.full_table_exported
						data.incremental_table_exported
						event.created
						event.updated
						flag.created
						local_chapter.last_organiser.deleted
						local_chapter.organiser_request.created
						member.deleted.resources_transferred
						petition.flagged
						petition.inappropriate.creator_message
						petition.launched
						petition.launched.ham
						petition.reactivated
						petition.updated
						petition.edited
						signature.created
						unsubscribe.created
						locale.created
						forum.message.requires_moderation
				] + @join_form.message_types).uniq, 
				@join_form.message_types
			)
	end

end
