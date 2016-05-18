module ApplicationHelper

	def set_title(title)
		content_for(:title, title)
	end

	def get_title(title)
		if title.blank?
			"Join a union!"
		else
			title
		end
	end

	def union_logo
		if @union && @union.logo.thumb.present?
			@union.logo.thumb.url
		else
			image_path('logo.png')
		end
	end 

	def profile_thumb(person)		
		unless person.attachment.blank?
			image_tag person.attachment.thumb.url, class: "profile_thumb"
		else
			"<span class=\"glyphicon glyphicon-user\"></span>".html_safe
		end
	end

	def other_languages
		l = locale.to_s
		l = "en" if l == "en-AU"
		Rails.application.config.languages.except(l)
	end

	def profile_logo(person)		
		unless person.attachment.blank?
			image_tag person.attachment.quote.url, class: "profile_logo"
		end
	end

	def pencil_button
		"<span class=\"small glyphicon glyphicon-pencil\"/>".html_safe 
	end

	def cog_button
		"<span class=\"small glyphicon glyphicon-cog\"/>".html_safe 
	end

	def gender_options(person)
    options_for_select(
      [
        [t('gender.male'), 'M'], 
        [t('gender.female'), 'F'],
        [t('gender.other'), 'N']
		  ], 
      person.gender
    )
  end

  def owner_union
  	#Rails.application.config.owner_union ||= Union.find_by_short_name(ENV['OWNER_UNION']) rescue nil # Added for tests, since I couldn't get seeds to work
		#Rails.application.config.owner_union
		Union.find_by_short_name(ENV['OWNER_UNION']) rescue nil
	end

	def owner?
		return false unless current_person.present?
		return false unless owner_union.present?
		current_person.union.id == owner_union.id 
	end

	def can_edit_union?(union)
		if current_person.present?
			if union.blank? || owner? || current_person.union.id == union.id
				true
			else
				false
			end 
		else
			false
		end
	end

	def selected_option(entity)
		entity ? 
        options_for_select([[entity.name, entity.id]], entity.id) :
        []
	end

	def offline_people()
    Person.where(["not (invitation_accepted_at is null or id in (?))", Secpubsub.presence.keys])
  end

  def local_time_tag(t)
  	content_tag(:span, I18n.l(t, format: :long), data: { time: t.iso8601 })
  end

  # HELPER FOR MAKING A SHORT ROUTE - is there a better away
  def join_form_id(join_form)
    # HACK TO PREVENT PEOPLE BOOKMARKING MY ALTERNATIVE TO GLOBALIZE HACK
    join_form_id = join_form.short_name.downcase
    join_form_id.gsub("-zh-tw", "")
  end

  def subscription_form_path(subscription)
    join_form = subscription.join_form
    union = join_form.union

    if subscription.id
      #union_join_form_subscription_path(union.short_name, join_form.short_name, subscription.token)
      #"/#{locale}/#{union.short_name.downcase}/#{join_form_id(join_form)}/join/#{subscription.token}"
    	edit_join_path(locale, union.short_name, join_form.short_name, subscription.token)
    else
      #"/#{locale}/#{union.short_name.downcase}/#{join_form_id(join_form)}/join"
    	new_join_path(locale, union.short_name, join_form.short_name)
    end
  end

  def subscription_short_path
    "/#{locale}/#{@union.short_name.downcase}/#{join_form_id(@join_form)}/#{@subscription.token}"
  end  
end
