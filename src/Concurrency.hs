{-# LANGUAGE RecordWildCards #-}

module Concurrency where

import Control.Concurrent.Async
import Control.Concurrent.STM
import Control.Concurrent.STM.TChan
import Control.Lens
import Control.Monad
import Control.Monad.STM

import Data.Map.Lazy (Map)
import qualified Data.Map.Lazy as M
import Data.Text (Text)
import Database.Persist
import Database.Persist.Postgresql
  ( ConnectionString
  , SqlPersistT
  , runMigration
  , withPostgresqlConn
  )

import Database
import Schema
import Socket.Types

-- Fork a new thread for each table that writes game updates received from the table channel to the DB
forkGameDBWriters :: ConnectionString -> Lobby -> IO [Async ()]
forkGameDBWriters connString (Lobby lobby) =
  sequence $
  (\(tableName, Table {..}) -> forkGameDBWriter connString channel tableName) <$>
  M.toList lobby

-- Looks up the tableName in the DB to get the key and if no corresponsing  table is found in the db then
-- we insert a new table to the db. This step is necessary as we use the TableID as a foreign key in the
-- For Game Entities in the DB. 
-- After we have the TableID we fork a new process which listens to the channel which emits new game states
-- for a given table. For each new game state msg received we write the new game state into the DB.
forkGameDBWriter ::
     ConnectionString -> TChan MsgOut -> TableName -> IO (Async ())
forkGameDBWriter connString chan tableName = do
  maybeTableEntity <- dbGetTableEntity connString tableName
  case maybeTableEntity of
    Nothing -> do
      tableKey <- dbInsertTableEntity connString tableName
      forkGameWriter tableKey
    Just (Entity tableKey _) -> forkGameWriter tableKey
  where
    forkGameWriter tableKey =
      async (writeNewGameStatesToDB connString chan tableKey)

writeNewGameStatesToDB ::
     ConnectionString -> TChan MsgOut -> Key TableEntity -> IO ()
writeNewGameStatesToDB connString chan tableKey = do
  dupChan <- atomically $ dupTChan chan
  forever $ do
    chanMsg <- atomically $ readTChan dupChan
    case chanMsg of
      (NewGameState tableName game) ->
        void (dbInsertGame connString game tableKey)
      _ -> return ()
