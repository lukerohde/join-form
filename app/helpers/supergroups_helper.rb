module SupergroupsHelper
	
	def supergroup
		@klass.name.downcase
	end

	def supergroups
		@klass.name.pluralize.downcase
	end

	def logo_image
		unless @supergroup.logo.blank?
			image_tag @supergroup.logo.url, class: "logo-image"
		end
	end

	def logo_thumb(supergroup)
		unless supergroup.logo.blank?
			image_tag supergroup.logo.thumb.url, class: "logo-thumb"
		end
	end

	def banner_title
		  link_to  @supergroup.name, "http://#{@supergroup.www}", data: {short_name: @supergroup.short_name, name: @supergroup.name}, class: "banner-link"
	end
end
