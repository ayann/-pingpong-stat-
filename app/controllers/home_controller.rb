class HomeController < ApplicationController
	before_action :create_player1,:create_player2, only: [:create]
	
	def create
		@partie = Partie.new(params_partie)
		@partie.player_1_id=@player1.id
		@partie.player_2_id=@player2.id
		respond_to do |format|
		  if @partie.save
		  	if params_partie[:score_1] > params_partie[:score_2]
		  		#Player 1 gagne
		  		score_p_1=1
		  		score_p_2=0
		  	elsif params_partie[:score_1] < params_partie[:score_2]
		  		#Player 2 gagne
		  		score_p_1=0
		  		score_p_2=1
		  	end
		  	#calcul elo Player 1
		  		player1_new_elo= calcul_new_elo(@player1.elo,score_p_1,@player2.elo)
		  		player1_variation= variation(player1_new_elo,@player1.elo)
		  		# player1_pourcentage= pourcentage(estimation(@player1.elo,@player2.elo))
		  	#calcul elo Player 2
		  		player2_new_elo= calcul_new_elo(@player2.elo,score_p_2,@player1.elo)
		  		player2_variation= variation(player2_new_elo,@player2.elo)
		  		# player2_pourcentage= pourcentage(estimation(@player2.elo,@player2.elo))
		  	#enregistrer en BDD
		  		@player1.update(:elo =>player1_new_elo, :variation =>player1_variation)
		  		@player2.update(:elo =>player2_new_elo, :variation =>player2_variation)
		    format.html { redirect_to home_index_path, :flash => { :notice => "Partie Enregistree" }}
		  else
		  	reset_player(@player1)
		  	reset_player(@player2)
		    format.html { redirect_to home_index_path, :flash => { :error => "veillez remplir correctement les champs" }}
		  end
		end
	end

	def index
	end

	def show
		id=params[:id]
		@player=Player.find(id)
		@partie=Partie.where("player_1_id = ?", id).select("score_1, created_at") + Partie.where("player_2_id = ?", id).select("score_2 AS score_1 , created_at")
		@partie.sort_by!{ |partie| partie.created_at} 
	end

	def afficher
		@players= Player.all.order('elo desc')
	end

	private

	def params_partie
		params.require(:match).permit(:player_1_id, :player_2_id, :score_1, :score_2)
	end

	def create_player1
		@player1= Player.find_by name: params[:match][:player_1]
		if @player1
			nb_match=@player1.nb_match+1
			unless @player1.classe
				if nb_match>debut_classe
					@player1.update(:nb_match =>nb_match, :classe =>1)
				else
					@player1.update(:nb_match =>nb_match)
				end 
			else	
				@player1.update(:nb_match =>nb_match)
			end
		else
			@player1= Player.new(:name=>params[:match][:player_1],:nb_match =>1,:classe =>0,:elo =>elo_depart)
			unless @player1.save
				flash[:error]="veillez remplir tous les champs"
				redirect_to home_index_path
			end
		end
		return @player1
	end

	def create_player2
		@player2 = Player.find_by name: params[:match][:player_2]
		if @player2
			nb_match=@player2.nb_match+1
			unless @player2.classe
				if nb_match>debut_classe
					@player2.update(:nb_match =>nb_match, :classe =>1)
				else
					@player2.update(:nb_match =>nb_match)
				end 
			else	
				@player2.update(:nb_match =>nb_match)
			end
		else
			@player2= Player.new(:name=>params[:match][:player_2],:nb_match =>1,:classe =>0,:elo =>elo_depart)
			unless @player2.save
				@player1.destroy
				flash[:error]="veillez remplir tous les champs"
				redirect_to home_index_path
			end
		end
		return @player2
	end

	def reset_player(player)
		nb_match=player.nb_match
		if nb_match==1
			player.destroy
		else
			nb_match -=1
			if nb_match==3
				player.update(:nb_match=>5,classe=>0)
			else
				player.update(:nb_match=>nb_match)
			end
		end
	end

	def elo_depart
		500
	end

	def debut_classe
		3
	end

	def estimation(elo_joueur, elo_adversaise)
		1.0/(1 + 10**((elo_adversaise-elo_joueur)/400))
	end
	def calcul_new_elo(elo_joueur,score,elo_adversaise)
		# Calcul de la nouveau point elo
		new_elo = elo_joueur + valeur_k(elo_joueur) * (score - estimation(elo_joueur, elo_adversaise))
		
		#  On ne veut personne en dessous d'une cote elo de 300
		if new_elo<300
			new_elo=300
		end
		return new_elo
	end
	def valeur_k(elo)
		if elo < 1000
			k = 80
		elsif elo >= 1000 && elo < 2000
			k = 50
		elsif elo >= 2000 && elo <= 2400
			k = 30
		else elo > 2400
			k = 20
		end
		return k
	end
	def variation(elo_joueur,new_elo)
		new_elo - elo_joueur
	end
	def pourcentage(estimation)
		estimation*100
	end
end
