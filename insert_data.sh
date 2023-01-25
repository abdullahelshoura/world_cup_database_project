#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.
echo $($PSQL "TRUNCATE teams,games")
RESTART_TEAM_ID=$($PSQL 'ALTER SEQUENCE teams_team_id_seq RESTART WITH 1')
RESTART_GAME_ID=$($PSQL 'ALTER SEQUENCE games_game_id_seq RESTART WITH 1')
############---------- INSERT TEAMS DATA -----------###############
cat games.csv | while IFS="," read YEAR ROUND WINNER OPPONENT WGOALS OGOALS
do
  if [ $YEAR != year ]
  then

    #get team_id
    if [[ $ROUND = Eighth-Final ]] 
    then
      TEAM_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER' AND name='$OPPONENT'")
  
      #if not found
      if [[ -z $TEAM_ID ]]
      then
  
        #insert teams
        INSERT_TEAMS=$($PSQL "WITH data(name) AS (
           VALUES ('$WINNER'),('$OPPONENT') 
           )
           INSERT INTO teams(name) 
           SELECT d.name
           FROM data d 
           WHERE NOT EXISTS(SELECT name FROM teams t WHERE t.name=d.name)")
        if [[ $INSERT_TEAMS = "INSERT 0 2" ]]
        then
          echo Inserted into teams, $WINNER $OPPONENT
        elif [[ $INSERT_TEAMS = "INSERT 0 1" ]]
        then
          WINNER_INSERTED=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER'")
          OPPONENT_INSERTED=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT'")
          if [[ $WINNER_INSERTED > $OPPONENT_INSERTED ]]
          then
            echo Inserted into teams, $WINNER 
          else
            echo Inserted into teams, $OPPONENT
          fi
        fi 
      fi
    fi
  fi
done
echo -e "\nALL TEAMS PARTICIPATED IN THIS HAVE BEEN ADDED\n"



############---------- INSERT GAMES DATA -----------###############
cat games.csv | while IFS="," read YEAR ROUND WINNER OPPONENT WGOALS OGOALS
do

  if [ $YEAR != year ]
  then
    
    #get game and teams ids
    WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER'")
    OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT'")
    GAME_ID=$($PSQL "SELECT game_id FROM games WHERE year=$YEAR AND round='$ROUND' AND winner_id=$WINNER_ID")
    
    #if not found
    if [[ -z $GAME_ID ]]
    then

      #insert games
      INSERT_GAMES=$($PSQL "INSERT INTO games(year,round,winner_id,opponent_id,winner_goals,opponent_goals) VALUES ($YEAR,'$ROUND',$WINNER_ID,$OPPONENT_ID,$WGOALS,$OGOALS)")
      if [[ $INSERT_GAMES = "INSERT 0 1" ]]
      then
          echo Inserted into games, $YEAR $ROUND 
      fi

    fi

  fi
done
echo -e "\nALL ALL DONE!!! \n"
