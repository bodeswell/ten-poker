{-# LANGUAGE OverloadedStrings #-}

module Poker.UtilsSpec where

import Control.Lens
import Data.List
import Data.List.Lens
import Data.Text (Text)
import qualified Data.Text as T
import Test.Hspec

import HaskellWorks.Hspec.Hedgehog
import           Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range

import Poker.ActionValidation
import Poker.Game.Utils
import Poker.Poker
import Poker.Types


initialGameState' = initialGameState initialDeck

player1 =
  Player
    { _pockets = Nothing
    , _chips = 2000
    , _bet = 0
    , _playerState = In
    , _playerName = "player1"
    , _committed = 100
    , _actedThisTurn = True
    }

player2 =
  Player
    { _pockets = Nothing
    , _chips = 2000
    , _bet = 0
    , _playerState = Folded
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
    , _playerState = In
    , _playerName = "player3"
    , _committed = 0
    , _actedThisTurn = False
    }

player5 =
  Player
    { _pockets = Nothing
    , _chips = 4000
    , _bet = 4000
    , _playerState = In
    , _playerName = "player5"
    , _committed = 4000
    , _actedThisTurn = True
    }

player6 =
  Player
    { _pockets = Nothing
    , _chips = 2000
    , _bet = 200
    , _playerState = In
    , _playerName = "player6"
    , _committed = 250
    , _actedThisTurn = True
    }

bettingFinishedGame =
  ((players .~ [player1, player2]) . (street .~ PreFlop)) initialGameState'

bettingNotFinishedGame =
  ((players .~ [player1, player2, player3, player4]) . (street .~ PreFlop))
    initialGameState'

spec = do
  describe "ModInc" $ do
    it "should increment in modulo fashion" $ do
      modInc 1 0 2 `shouldBe` 1
      modInc 1 1 1 `shouldBe` 0
      modInc 1 6 7 `shouldBe` 7
    it "result should always be greater than zero" $ do
      requireProperty $ do
        i <- forAll $ Gen.int $ Range.linear 0 9
        (modInc 1 i 9 >= 0) === True
  