require 'rubygems'
require 'sinatra'
require 'pry'


set :sessions, true

helpers do 
  def calculate_total(hand)
    total = 0 
    hand.each do |card|
      if card[1] == 'ace'
        total += 11
      else
        total += card[1].to_i == 0 ? 10 : card[1].to_i
      end
    end

    if total > 21
      hand.each do |card|
        if card[1] == 'ace' && total > 21
          total -= 10
        end
      end
    end
    return total
  end


  def get_image(card)
    return "/images/cards/#{card[0]}_#{card[1]}.jpg"
  end

end

before do
  @show_hit_or_stay_buttons = true
  @dealer_deal_button = false
end

get '/' do
  if params[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :form
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb :form
  else
    session[:player_name] = params[:player_name]
    redirect '/game'
  end
end

get '/game' do
  session[:deck] = []
  suits = ['hearts', 'diamonds', 'spades', 'clubs']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'jack', 'queen', 'king', 'ace']
  suits. each do |suit|
    values.each do |value|
      session[:deck] << [suit, value]
    end
  end
  session[:deck].shuffle!
  session[:player_hand] = []
  session[:dealer_hand] = []
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  player_total = calculate_total(session[:player_hand])
  if player_total == 21
      @success = "Congratulations! #{session[:player_name]} has hit BlackJack!"
      @show_hit_or_stay_buttons = false
  end
  erb :game
end

post '/game/player/hit' do
  session[:player_hand] << session[:deck].pop
  player_total = calculate_total(session[:player_hand])
  if player_total == 21
      @success = "Congratulations! #{session[:player_name]} has hit BlackJack!"
      @show_hit_or_stay_buttons = false
  elsif player_total > 21
    @error = "Sorry, it looks like you busted."
    @show_hit_or_stay_buttons = false
  end
  erb :game
end

post '/game/player/stay' do
  @success = "You have chosen to stay."
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
  erb :game
end

get '/game/dealer' do
  @show_hit_or_stay_buttons = false
  dealer_total = calculate_total(session[:dealer_hand])
  if dealer_total == 21
    @error = "Sorry, dealer hit blackjack!"
  elsif dealer_total > 21
    @success = "Congratulations, dealer busted. You win!"
  elsif dealer_total >= 17
    redirect '/game/compare'
  else
    @dealer_deal_button = true
  end
  erb :game   
end

post '/game/dealer/deal' do
  session[:dealer_hand] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @dealer_deal_button = false
  @show_hit_or_stay_buttons = false
  player_total = calculate_total(session[:player_hand])
  dealer_total = calculate_total(session[:dealer_hand])
  if player_total < dealer_total
    @error = "Sorry, you lost."
  elsif player_total > dealer_total
    @success = "Congrats, you won!"
  else
    @success = "Its a tie"
  end
  erb :game
end
