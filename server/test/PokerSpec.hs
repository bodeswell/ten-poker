{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}

module PokerSpec where

import Control.Lens
import Data.Aeson
import Data.Either
import Data.List
import Data.Maybe
import Data.Text (Text)
import qualified Data.Text as T
import Test.Hspec

import HaskellWorks.Hspec.Hedgehog
import           Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range

import Poker.ActionValidation
import Poker.Game.Actions
import Poker.Game.Game
import Poker.Poker
import Poker.Types

import Poker.Generators
import Poker.Game.Utils

player1 =
  Player
    { _pockets =
        Just $ PocketCards
            Card {rank = Three, suit = Diamonds}
            Card {rank = Four, suit = Spades}
    , _chips = 2000
    , _bet = 50
    , _playerState = In
    , _playerName = "player1"
    , _committed = 50
    , _actedThisTurn = True
    }

player2 =
  Player
    { _pockets =
        Just $ PocketCards
          Card {rank = Three, suit = Clubs}
          Card {rank = Four, suit = Hearts}
    , _chips = 0
    , _bet = 0
    , _playerState = In
    , _playerName = "player2"
    , _committed = 50
    , _actedThisTurn = False
    }

player3 =
  Player
    { _pockets = Nothing
    , _chips = 2000
    , _bet = 0
    , _playerState = In
    , _playerName = "player3"
    , _committed = 50
    , _actedThisTurn = False
    }

player4 =
  Player
    { _pockets = Nothing
    , _chips = 2000
    , _bet = 0
    , _playerState = SatOut
    , _playerName = "player4"
    , _committed = 0
    , _actedThisTurn = False
    }

player5 =
  Player
    { _pockets =
        Just $ PocketCards
           Card {rank = King, suit = Diamonds}
           Card {rank = Four, suit = Spades}
         
    , _chips = 2000
    , _bet = 50
    , _playerState = In
    , _playerName = "player1"
    , _committed = 50
    , _actedThisTurn = True
    }

initPlayers = [player1, player2, player3]

prop_canProgressIsEquivalentToAllActed :: Property
prop_canProgressIsEquivalentToAllActed = withDiscards 225 . property $ do
    g@Game{..} <- forAll $ genGame actionStages allPStates
    let 
      playerCanAct = any (canPlayerAct _maxBet) _players
      actionPossible = ((length $ getActivePlayers _players) >= 2) && playerCanAct
    canProgressGame g === not actionPossible
  where 
    actionStages = [PreFlop, Flop, Turn, River]
    canPlayerAct maxBet' Player{..} =
      _chips > 0 && (not _actedThisTurn || (_playerState == In && (_bet < maxBet')))

spec = describe "Poker" $ do  
    it " games" $ require prop_canProgressIsEquivalentToAllActed
