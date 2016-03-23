# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

subscription_helper_ready = ->
	Stripe.setPublishableKey($('meta[name="stripe-key"]').attr('content'))
	subscription.setupForm()

subscription =
  setupForm: ->
    $('#new_subscription').submit ->
      $('input[type=submit]').attr('disabled', true)
      if $('#subscription_account_number').length
        subscription.processCard()
        false
      else
        true
  
  processCard: ->
    card =
      number: $('#subscription_account_number').val()
      cvc: $('#subscription_ccv').val()
      expMonth: $('#subscription_expiry_month').val()
      expYear: $('#subscription_expiry_year').val()
    Stripe.createToken(card, subscription.handleStripeResponse)
  
  handleStripeResponse: (status, response) ->
    if status == 200
      $('#subscription_stripe_token').val(response.id)
      $('#new_subscription')[0].submit()
    else
      $('#stripe_error').text(response.error.message)
      $('input[type=submit]').attr('disabled', false)

$(document).ready(subscription_helper_ready);
$(document).on('page:load', subscription_helper_ready);
