{-# LANGUAGE RecordWildCards    #-}
{-# LANGUAGE FlexibleContexts   #-}

module Haskell.Interop.Prime.Options (
  defaultOptions,
  defaultOptionsHaskell,
  defaultOptionsPurescript,
  defaultFieldNameTransform,
  defaultJsonNameTransform,
  defaultJsonTagNameTransform,

  defaultOptionsClean,
  defaultOptionsCleanHaskell,
  defaultOptionsCleanPurescript,
  defaultFieldNameTransformClean,
  defaultJsonNameTransformClean,
  defaultJsonTagNameTransformClean,

  defaultOptions_Purescript_adarqui,
  defaultOptions_Haskell_adarqui,

  defaultTypeMap,
  defaultReservedMap,

  defaultPurescriptMks,
  defaultPurescriptMkGs,
  defaultPurescriptApiMkGs,
  defaultPurescriptApiStringMkGs,
  defaultPurescriptConvertMkGs,

  defaultHaskellMks,
  defaultHaskellMkGs,
  defaultHaskellApiMkGs,
  defaultHaskellApiStringMkGs,
  defaultHaskellConvertMkGs,
) where



import           Data.Char                   (toLower)
import           Data.List                   (isPrefixOf, isSuffixOf)
import qualified Data.Map                    as M
import           Data.Transform.UnCamel      (unCamelSource)
import           Prelude

import           Haskell.Interop.Prime.Misc
import           Haskell.Interop.Prime.Types



langToMap :: Lang -> M.Map String String
langToMap LangHaskell    = M.empty
langToMap LangPurescript = defaultTypeMap



defaultOptionsPurescript :: FilePath -> InteropOptions
defaultOptionsPurescript = defaultOptions LangPurescript

defaultOptionsHaskell :: FilePath -> InteropOptions
defaultOptionsHaskell path = (defaultOptions LangHaskell path) { psDataToNewtype = False }

defaultOptions :: Lang -> FilePath -> InteropOptions
defaultOptions lang path = InteropOptions {
  fieldNameTransform = defaultFieldNameTransform,
  jsonNameTransform = defaultJsonNameTransform,
  jsonTagNameTransform = defaultJsonTagNameTransform,
  typeMap = langToMap lang,
  reservedMap = defaultReservedMap,
  spacingNL = 2,
  spacingIndent = 2,
  lang = lang,
  psDataToNewtype = True,
  filePath = path,
  debug = False
}

defaultFieldNameTransform :: StringTransformFn
defaultFieldNameTransform _ s = s

defaultJsonNameTransform :: StringTransformFn
defaultJsonNameTransform _ s = s

defaultJsonTagNameTransform :: StringTransformFn
defaultJsonTagNameTransform _ s = s




defaultOptionsCleanPurescript :: FilePath -> InteropOptions
defaultOptionsCleanPurescript = defaultOptionsClean LangPurescript

defaultOptionsCleanHaskell :: FilePath -> InteropOptions
defaultOptionsCleanHaskell = defaultOptionsClean LangHaskell

defaultOptionsClean :: Lang -> FilePath -> InteropOptions
defaultOptionsClean lang path = InteropOptions {
  fieldNameTransform = defaultFieldNameTransformClean,
  jsonNameTransform = defaultJsonNameTransformClean,
  jsonTagNameTransform = defaultJsonTagNameTransformClean,
  typeMap = langToMap lang,
  reservedMap = defaultReservedMap,
  spacingNL = 2,
  spacingIndent = 2,
  lang = lang,
  psDataToNewtype = True,
  filePath = path,
  debug = False
}

-- The logic for checking empty string after stripPrefix:
--
-- This becomes important when a field within a record is named exactly after the constructor,
-- which results in an empty name if you 'strip off' the constructor prefix. So, we keep the
-- original field name in this case.
--

defaultFieldNameTransformClean :: StringTransformFn
defaultFieldNameTransformClean nb s =
  if isPrefixOf lower_nb lower_s
    then firstToLower fixed
    else s
  where
  lower_nb = map toLower nb
  lower_s  = map toLower s
  stripped = drop (length lower_nb) s
  fixed    =
    case stripped of
      "" -> s
      v  -> v

defaultJsonNameTransformClean :: StringTransformFn
defaultJsonNameTransformClean nb s =
  if isPrefixOf lower_nb lower_s
    then dropWhile (=='_') $ dropSuffix $ map toLower $ unCamelSource '_' fixed
    else dropWhile (=='_') $ dropSuffix $ map toLower $ unCamelSource '_' s
  where
  lower_nb = map toLower nb
  lower_s  = map toLower s
  stripped = drop (length lower_nb) s
  fixed    =
    case stripped of
      "" -> s
      v  -> v
  -- this is somewhat hacky:
  -- if a json tag ends in _p, we assume it's part of the reserved map, ie, "data_p" == dataP
  -- so trim the _p off of the end so that we don't have to send json tags with _p from the server side
  -- this could be done in Template.hs, but i'd rather just make it user customizable for now.
  -- thnx.
  dropSuffix s' =
    if isSuffixOf "_p" s'
      then take (length s' - 2) s'
      else s'

defaultJsonTagNameTransformClean :: StringTransformFn
defaultJsonTagNameTransformClean _ s = s





defaultOptions_Purescript_adarqui :: FilePath -> InteropOptions
defaultOptions_Purescript_adarqui = defaultOptionsCleanPurescript

defaultOptions_Haskell_adarqui :: FilePath -> InteropOptions
defaultOptions_Haskell_adarqui path =
  (defaultOptionsHaskell path) {
    jsonNameTransform = defaultJsonNameTransformClean
  }





defaultTypeMap :: M.Map String String
defaultTypeMap =
  M.fromList
    [ ("Integer", "Int")
    , ("Int64", "Int") -- TODO FIXME: Should use purescript-big-integers
    , ("Double", "Number")
    , ("Float", "Number")
    , ("Bool", "Boolean")
    , ("Set", "Array")
    , ("List", "Array")
    , ("()", "Unit")
    , ("Text", "String")
    , ("ByteString", "String")
    , ("UTCTime", "Date")
    , ("Array Char", "String")
    -- instead of adding in a bunch of logic into the internals, for now let's just
    -- be explicit about it in the user-supplyable type map
    -- this can be controlled entirely by the user, in the call to mkExport, mkApi, mkConvert etc.
    , ("(Array Char)", "String")
    ]



defaultReservedMap :: M.Map String String
defaultReservedMap =
  M.fromList
    [ ("data", "dataP")
    , ("type", "typeP")
    , ("class", "classP")
    , ("module", "moduleP")
    , ("let", "letP")
    ]



defaultPurescriptMks :: [Mk]
defaultPurescriptMks =
  [ MkType
  , MkTypeRows "R"
  , MkLens
  , MkMk
  , MkUnwrap
  , MkEncodeJson
  , MkDecodeJson
  , MkRequestable
  , MkRespondable
  , MkDecode
  , MkShow
  , MkRead
  , MkEq
  ]



defaultPurescriptMkGs :: String -> [MkG]
defaultPurescriptMkGs header =
  [ MkGPurescriptImports
  , MkGHeader header
  , MkGLensFields
  , MkGFooter "-- footer"
  ]



defaultPurescriptApiMkGs :: String -> [MkG]
defaultPurescriptApiMkGs header =
  [ MkGPurescriptApiImports
  , MkGHeader header
  , MkGFooter "-- footer"
  ]



defaultPurescriptApiStringMkGs :: String -> [MkG]
defaultPurescriptApiStringMkGs header =
  [ MkGPurescriptApiStringImports
  , MkGHeader header
  , MkGFooter "-- footer"
  ]



defaultPurescriptConvertMkGs :: String -> [MkG]
defaultPurescriptConvertMkGs header =
  [ MkGPurescriptConvertImports
  , MkGHeader header
  , MkGLensFields
  , MkGFooter "-- footer"
  ]



defaultHaskellMks :: [Mk]
defaultHaskellMks =
  [ MkType
  , MkTypeWith
      [ MkTypeOpts_StrictFields
      , MkTypeOpts_Deriving Deriving_Generic
      , MkTypeOpts_Deriving Deriving_Typeable
      , MkTypeOpts_Deriving Deriving_NFData
      , MkTypeOpts_Deriving Deriving_Show
      , MkTypeOpts_Deriving Deriving_Read
      , MkTypeOpts_Deriving Deriving_Eq
      , MkTypeOpts_Deriving Deriving_Ord
      , MkTypeOpts_Deriving Deriving_Enum
      ]
  , MkToJSON
  , MkFromJSON
  , MkShow
  , MkRead
  , MkEq
  ]



defaultHaskellMkGs :: String -> [MkG]
defaultHaskellMkGs header =
  [ MkGHaskellImports
  , MkGHeader header
  , MkGFooter "-- footer"
  ]



defaultHaskellApiMkGs :: String -> [MkG]
defaultHaskellApiMkGs header =
  [ MkGHaskellApiImports
  , MkGHeader header
  , MkGFooter "-- footer"
  ]



defaultHaskellApiStringMkGs :: String -> [MkG]
defaultHaskellApiStringMkGs header =
  [ MkGHaskellApiStringImports
  , MkGHeader header
  , MkGFooter "-- footer"
  ]



defaultHaskellConvertMkGs :: String -> [MkG]
defaultHaskellConvertMkGs header =
  [ MkGHaskellConvertImports
  , MkGHeader header
  , MkGFooter "-- footer"
  ]
