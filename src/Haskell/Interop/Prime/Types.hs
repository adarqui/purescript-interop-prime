{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE OverloadedStrings  #-}
{-# LANGUAGE RecordWildCards    #-}
{-# LANGUAGE TemplateHaskell    #-}
{-# OPTIONS -ddump-splices      #-}

module Haskell.Interop.Prime.Types (
  ExportT,
  Lang (..),
  Mk (..),
  MkG (..),
  Options (..),
  InteropOptions (..),
  InternalRep (..),
  InteropReader (..),
  InteropState (..),
  Api (..),
  ApiMethod (..),
  ApiParam (..),
  ApiEntry (..),
  Api_TH (..),
  ApiMethod_TH (..),
  ApiParam_TH (..),
  ApiEntry_TH (..),
  StringTransformFn,
) where



import           Control.Monad.Trans.RWS
import qualified Data.Map                as M
import           Language.Haskell.TH



data Lang
  = LangPurescript
  | LangHaskell
  deriving (Show)



data Mk
  = MkType
  | MkToJSON
  | MkFromJSON
  | MkUnwrap
  | MkMk
  | MkLens
  | MkEncodeJson
  | MkDecodeJson
  | MkRequestable
  | MkRespondable
  | MkIsForeign
  | MkShow
  deriving (Show)



data MkG
  = MkGPurescriptImports
  | MkGHaskellImports
  | MkGLensFields
  | MkGHeader String
  | MkGFooter String
  deriving (Show)



type StringTransformFn = String -> String -> String



data InteropOptions = InteropOptions {
  fieldNameTransform   :: StringTransformFn,
  jsonNameTransform    :: StringTransformFn,
  jsonTagNameTransform :: StringTransformFn,
  spacingNL            :: Int,
  spacingIndent        :: Int,
  typeMap              :: M.Map String String,
  reservedMap          :: M.Map String String,
  lang                 :: Lang,
  psDataToNewtype      :: Bool,
  filePath             :: FilePath,
  debug                :: Bool
}



data Options = Options {
  psInterop :: InteropOptions,
  psMkGs    :: [MkG],
  hsInterop :: InteropOptions,
  hsMkGs    :: [MkG]
}



data InternalRep
  = NewtypeRecIR String String [(String, String)]
  | NewtypeNormalIR String String
  | DataRecIR String String [(String, String)]
  | DataNormalIR String [(String, [String])]
  | TypeIR String String
  | EmptyIR
  deriving (Show)



data InteropReader = InteropReader {
  irInterop :: InteropOptions,
  irFields  :: [String]
}


data InteropState = InteropState {
  isRep :: InternalRep
}



data Api = Api {
  apiPrefix  :: String,
  apiEntries :: [ApiEntry]
} deriving (Show)



data ApiMethod
  = ApiGET    String
  | ApiPOST   String String
  | ApiPUT    String String
  | ApiDELETE String
  deriving (Show)



data ApiParam
  = Par [(String, String)]
  | ParBy String String
  | ParNone
  deriving (Show)



data ApiEntry
  = ApiEntry String [ApiParam] [ApiMethod]
  deriving (Show)



data Api_TH = Api_TH {
  apiPrefix_TH  :: String,
  apiEntries_TH :: [ApiEntry_TH]
} deriving (Show)



data ApiMethod_TH
  = ApiGET_TH    Name
  | ApiPOST_TH   Name Name
  | ApiPUT_TH    Name Name
  | ApiDELETE_TH Name
  deriving (Show)



data ApiParam_TH
  = Par_TH [(String, Name)]
  | ParBy_TH String Name
  | ParNone_TH
  deriving (Show)



data ApiEntry_TH
  = ApiEntry_TH String [ApiParam_TH] [ApiMethod_TH]
  deriving (Show)



-- newtype RWST r w s m a
type ExportT = RWS InteropReader () InteropState