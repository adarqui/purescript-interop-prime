{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE RecordWildCards      #-}

module Purescript.Interop.Prime.Template (
  tplType,
  tplLensP,
  tplLensFields,
  tplNewtypeRecord,
  tplDataRecord,
  tplRecord,
  tplDataNormal,
  tplMk,
  tplUnwrap,
  tplToJSON_Record,
  tplFromJSON_Record,
  tplToJSON_SumType,
  tplFromJSON_SumType,
  tplEncodeJson_Record,
  tplDecodeJson_Record,
  tplEncodeJson_SumType,
  tplDecodeJson_SumType,
  tplRequestable,
  tplRespondable,
  tplIsForeign,
  tplShow_SumType,
  tplPurescriptImports,
  tplHaskellImports,
  tplHeader,
  tplFooter,
  tplJObject
) where



import           Data.List
import           Purescript.Interop.Prime.Misc
import           Purescript.Interop.Prime.Types
import           Text.Printf



default (String)



tplType :: InteropOptions -> String -> String -> String
tplType InteropOptions{..} base type_ =
  printf "type %s = %s\n" base type_



tplLensP :: InteropOptions -> String -> String -> [(String, String)] -> String
tplLensP InteropOptions{..} base constr fields =
     printf "_%s :: LensP %s {\n" base base
  ++ intercalateMap ",\n" (\(n,t) -> spaces spacingIndent ++ printf "%s :: %s" (fieldNameTransform base n) t) fields
  ++ "\n}\n"
  ++ printf "_%s f (%s o) = %s <$> f o\n" base constr constr



tplLensFields :: InteropOptions -> [String] -> String -> String
tplLensFields InteropOptions{..} fields s =
  s ++ (newlines spacingNL) ++ (intercalateMap (newlines spacingNL) tplLensField fields)



tplLensField :: String -> String
tplLensField field =
     printf "%s_ :: forall b a r. Lens { %s :: a | r } { %s :: b | r } a b\n" field field field
  ++ printf "%s_ f o = o { %s = _ } <$> f o.%s\n" field field field



tplNewtypeRecord :: InteropOptions -> String -> String -> [(String, String)] -> String
tplNewtypeRecord = tplRecord "newtype"



tplDataRecord :: InteropOptions -> String -> String -> [(String, String)] -> String
tplDataRecord opts@InteropOptions{..} =
  if psDataToNewtype
    then tplRecord "newtype" opts
    else tplRecord "data" opts



tplRecord :: String -> InteropOptions -> String -> String -> [(String, String)] -> String
tplRecord type_ InteropOptions{..} base constr fields =
     printf "%s %s = %s {\n" type_ base constr
  ++ intercalateMap ",\n" (\(n,t) -> spaces spacingIndent ++ printf "%s :: %s" (fieldNameTransform base n) t) fields
  ++ "\n}\n"



tplDataNormal :: InteropOptions -> String -> [(String, [String])] -> String
tplDataNormal InteropOptions{..} base fields =
     printf "data %s\n" base
  ++ spaces spacingIndent ++ "= "
  ++ intercalateMap (spaces spacingIndent ++ "| ") (\(n,t) -> printf "%s %s\n" n (intercalate " " t)) fields
  ++ "\n"



tplMk :: InteropOptions -> String -> String -> [(String, String)] -> String
tplMk InteropOptions{..} base constr fields =
     printf "mk%s :: " base
  ++ intercalateMap " -> " (\(_,t) -> t) (fields ++ [("tmp",base)]) ++ "\n"
  ++ printf "mk%s " base
  ++ intercalateMap " " (\(n,_) -> fieldNameTransform base n) fields ++ " =\n"
  ++ (spaces spacingIndent) ++ constr ++ "{"
  ++ intercalateMap ", " (\(n,_) -> fieldNameTransform base n) fields
  ++ "}\n"



-- TODO FIXME: need to also generate a type sig
--
tplUnwrap :: InteropOptions -> String -> String -> String
tplUnwrap InteropOptions{..} base constr =
    printf "unwrap%s (%s r) = r" base constr



tplToJSON_Record :: InteropOptions -> String -> String -> [(String, String)] -> String
tplToJSON_Record InteropOptions{..} base constr fields =
     instance_decl
  ++ spaces si1 ++ printf "toJSON (%s v) = object $\n" constr
  ++ spaces si2 ++ printf "[ \"tag\" .= \"%s\"\n" base
  ++ concatMap (\(n,_) -> spaces si2 ++ printf ", \"%s\" .= v.%s\n" (jsonNameTransform base n) (fieldNameTransform base n)) fields
  ++ spaces si2 ++ printf "]\n"
  where
  si1 = spacingIndent*1
  si2 = spacingIndent*2
  instance_decl =
    case lang of
      LangPurescript -> printf "instance %sToJson :: ToJSON %s where\n" (firstToLower base) base
      LangHaskell    -> printf "instance ToJSON %s where\n" base



tplFromJSON_Record :: InteropOptions -> String -> String -> [(String, String)] -> String
tplFromJSON_Record InteropOptions{..} base constr fields =
     instance_decl
  ++ spaces si1 ++ printf "parseJSON (%s o) = do\n" (tplJObject lang)
  ++ concatMap (\(n,_) -> spaces si2 ++ printf "%s <- o .: \"%s\"\n" (fieldNameTransform base n) (jsonNameTransform base n)) fields
  ++ spaces si2 ++ printf "return $ %s {\n" constr
  ++ intercalateMap ",\n" (\(n,_) -> spaces si3 ++ printf "%s %s %s" (fieldNameTransform base n)  eql (fieldNameTransform base n)) fields
  ++ "\n" ++ spaces si2 ++ "}\n"
  ++ spaces spacingIndent ++ printf "parseJSON x = fail $ \"Could not parse object: \" ++ show x\n"
  where
  si1 = spacingIndent*1
  si2 = spacingIndent*2
  si3 = spacingIndent*3
  instance_decl =
    case lang of
      LangPurescript -> printf "instance %sFromJSON :: FromJSON %s where\n" (firstToLower base) base
      LangHaskell    -> printf "instance FromJSON %s where\n" base
  eql =
    case lang of
      LangPurescript -> ":"
      LangHaskell    -> "="



tplToJSON_SumType :: InteropOptions -> String -> [(String, [String])] -> String
tplToJSON_SumType opts@InteropOptions{..} base fields =
     instance_decl
  ++ concatMap (\(f,vars) -> tplToJSON_SumType_Field opts f vars) fields
  where
  instance_decl =
    case lang of
      LangPurescript -> printf "instance %sToJSON :: ToJSON %s where\n" (firstToLower base) base
      LangHaskell    -> printf "instance ToJSON %s where\n" base



tplToJSON_SumType_Field :: InteropOptions -> String -> [String] -> String
tplToJSON_SumType_Field InteropOptions{..} field vars =
     spaces si1 ++ printf "toJSON (%s %s) = object $\n" field (intercalate " " vars')
  ++ spaces si2 ++ printf "[ \"tag\" .= \"%s\"\n" field
  ++
     (if null vars
        then spaces si2 ++ printf ", \"contents\" .= ([] :: Array String)\n"
        else spaces si2 ++ printf ", \"contents\" .= " ++ wrapContent vars (intercalateMap ", " ("toJSON " ++) vars') ++ "\n")
  ++ spaces si2 ++ "]\n"
  where
  si1 = spacingIndent
  si2 = spacingIndent*2
  vars' = vars_x $ length vars



tplFromJSON_SumType :: InteropOptions -> String -> [(String, [String])] -> String
tplFromJSON_SumType opts@InteropOptions{..} base fields =
     instance_decl
  ++ spaces si1 ++ printf "parseJSON (%s o) = do\n" (tplJObject lang)
  ++ spaces si2 ++ "tag <- o .: \"tag\"\n"
  ++ spaces si2 ++ "case tag of\n"
  ++ concatMap (\(f,vars) -> tplFromJSON_SumType_Field opts f vars) fields
  ++ spaces si1 ++ printf "parseJSON x = fail $ \"Could not parse object: \" ++ show x\n"
  where
  si1 = spacingIndent
  si2 = spacingIndent*2
  instance_decl =
    case lang of
      LangPurescript -> printf "instance %sFromJSON :: FromJSON %s where\n" (firstToLower base) base
      LangHaskell    -> printf "instance FromJSON %s where\n" base



tplFromJSON_SumType_Field :: InteropOptions -> String -> [String] -> String
tplFromJSON_SumType_Field InteropOptions{..} field vars =
     spaces si1 ++ printf "\"%s\" -> do\n" field
  ++
     (if null vars
       then spaces si2 ++ printf "return $ %s\n" field
       else
            spaces si2 ++ wrapContent vars (intercalate ", " vars') ++ " <- o .: \"contents\"\n"
         ++ spaces si2 ++ printf "%s <$> %s" field (intercalateMap " <*> " ("parseJSON " ++) vars') ++ "\n")
  ++ "\n"
  where
  si1 = spacingIndent*3
  si2 = spacingIndent*4
  vars' = vars_x $ length vars




tplEncodeJson_Record :: InteropOptions -> String -> String -> [(String, String)] -> String
tplEncodeJson_Record InteropOptions{..} base constr fields =
     instance_decl
  ++ spaces si1 ++ printf "encodeJson (%s o) =\n" constr
  ++ spaces si3 ++ printf " \"tag\" := \"%s\"\n" base
  ++ concatMap (\(n,_) -> spaces si2 ++ printf "~> \"%s\" := o.%s\n" (jsonNameTransform base n) (fieldNameTransform base n)) fields
  ++ spaces si2 ++ "~> jsonEmptyObject\n"
  where
  si1 = spacingIndent*1
  si2 = spacingIndent*2
  si3 = spacingIndent*3
  instance_decl =
    case lang of
      LangPurescript -> printf "instance %sEncodeJson :: EncodeJson %s where\n" (firstToLower base) base
      LangHaskell    -> haskellNotSupported



tplDecodeJson_Record :: InteropOptions -> String -> String -> [(String, String)] -> String
tplDecodeJson_Record InteropOptions{..} base constr fields =
     instance_decl
  ++ spaces si1 ++ "decodeJson o = do\n"
  ++ spaces si2 ++ "obj <- decodeJson o\n"
  ++ concatMap (\(n,_) -> spaces si2 ++ printf "%s <- obj .? \"%s\"\n" (fieldNameTransform base n) (jsonNameTransform base n)) fields
  ++ spaces si2 ++ printf "pure $ %s {\n" constr
  ++ intercalateMap ",\n" (\(n,_) -> spaces si3 ++ (fieldNameTransform base n)) fields
  ++ "\n" ++ spaces si2 ++ "}\n"
  where
  si1 = spacingIndent*1
  si2 = spacingIndent*2
  si3 = spacingIndent*3
  instance_decl =
    case lang of
      LangPurescript -> printf "instance %sDecodeJson :: DecodeJson %s where\n" (firstToLower base) base
      LangHaskell    -> haskellNotSupported



tplEncodeJson_SumType :: InteropOptions -> String -> [(String, [String])] -> String
tplEncodeJson_SumType opts@InteropOptions{..} base fields =
     instance_decl
  ++ concatMap (\(f,vars) -> tplEncodeJson_SumType_Field opts f vars) fields
  where
  instance_decl =
    case lang of
      LangPurescript -> printf "instance %sEncodeJson :: EncodeJson %s where\n" (firstToLower base) base
      LangHaskell    -> haskellNotSupported



tplEncodeJson_SumType_Field :: InteropOptions -> String -> [String] -> String
tplEncodeJson_SumType_Field InteropOptions{..} field vars =
     spaces si1 ++ printf "encodeJson (%s %s) =\n" field (intercalate " " vars')
  ++ spaces si3 ++ printf " \"tag\" := \"%s\"\n" field
  ++
     (if null vars
        then spaces si2 ++ printf "~> \"contents\" := ([] :: Array String)\n"
        else spaces si2 ++ printf "~> \"contents\" := " ++ wrapContent vars (intercalateMap ", " ("encodeJson " ++) vars') ++ "\n")
  ++ spaces si2 ++ "~> jsonEmptyObject\n"
  where
  si1 = spacingIndent
  si2 = spacingIndent*2
  si3 = spacingIndent*3
  vars' = vars_x $ length vars



tplDecodeJson_SumType :: InteropOptions -> String -> [(String, [String])] -> String
tplDecodeJson_SumType opts@InteropOptions{..} base fields =
     instance_decl
  ++ spaces si1 ++ "decodeJson json = do\n"
  ++ spaces si2 ++ "obj <- decodeJson json\n"
  ++ spaces si2 ++ "tag <- obj .? \"tag\"\n"
  ++ spaces si2 ++ "case tag of\n"
  ++ concatMap (\(f,vars) -> tplDecodeJson_SumType_Field opts f vars) fields
  ++ spaces si1 ++ printf "decodeJson x = fail $ \"Could not parse object: \" ++ show x\n"
  where
  si1 = spacingIndent
  si2 = spacingIndent*2
  instance_decl =
    case lang of
      LangPurescript -> printf "instance %sDecodeJson :: DecodeJson %s where\n" (firstToLower base) base
      LangHaskell    -> haskellNotSupported



tplDecodeJson_SumType_Field :: InteropOptions -> String -> [String] -> String
tplDecodeJson_SumType_Field InteropOptions{..} field vars =
     spaces si1 ++ printf "\"%s\" -> do\n" field
  ++
     (if null vars
       then spaces si2 ++ printf "return $ %s\n" field
       else
            spaces si2 ++ wrapContent vars (intercalate ", " vars') ++ " <- obj .? \"contents\"\n"
         ++ spaces si2 ++ printf "%s <$> %s" field (intercalateMap " <*> " ("decodeJson " ++) vars') ++ "\n")
  ++ "\n"
  where
  si1 = spacingIndent*4
  si2 = spacingIndent*5
  vars' = vars_x $ length vars



tplRequestable :: InteropOptions -> String -> String
tplRequestable InteropOptions{..} base =
     printf "instance %sRequestable :: Requestable %s where\n" (firstToLower base) base
  ++ spaces si1 ++ "toRequest s =\n"
  ++ spaces si2 ++ "let str = printJson (encodeJson s) :: String\n"
  ++ spaces si2 ++ "in toRequest str\n"
  where
  si1 = spacingIndent
  si2 = spacingIndent*2



tplRespondable :: InteropOptions -> String -> String
tplRespondable InteropOptions{..} base =
     printf "instance %sRespondable :: Respondable %s where\n" (firstToLower base) base
  ++ spaces si1 ++ "responseType =\n"
  ++ spaces si2 ++ "Tuple Nothing JSONResponse\n"
  ++ spaces si1 ++ "fromResponse f = case readString f of\n"
  ++ spaces si2 ++ "Right s -> readJSON s\n"
  ++ spaces si2 ++ "Left er -> Left er\n"
  where
  si1 = spacingIndent
  si2 = spacingIndent*2



tplIsForeign :: InteropOptions -> String -> String
tplIsForeign InteropOptions{..} base =
     printf "instance %sIsForeign :: IsForeign %s where\n" (firstToLower base) base
  ++ spaces si1 ++ "read f = case readString f of\n"
  ++ spaces si2 ++ "Right s -> readJSON s\n"
  ++ spaces si2 ++ "Left er -> Left er\n"
  where
  si1 = spacingIndent
  si2 = spacingIndent*2



tplShow_SumType :: InteropOptions -> String -> [(String, [String])] -> String
tplShow_SumType opts@InteropOptions{..} base fields =
     instance_decl
  ++ concatMap (\(f,vars) -> tplShow_SumType_Field opts f vars) fields
  where
  instance_decl =
    case lang of
      LangPurescript -> printf "instance %sShow :: Show %s where\n" (firstToLower base) base
      LangHaskell    -> haskellNotSupported



tplShow_SumType_Field :: InteropOptions -> String -> [String] -> String
tplShow_SumType_Field InteropOptions{..} field vars =
 (if null vars
    then
      spaces si1 ++ printf "show (%s) = \"%s\"" field field
    else
      spaces si1 ++ printf "show (%s %s) = \"%s: \" ++ " field (intercalate " " vars') field ++ (intercalateMap " ++ \" \" ++ " (printf "show %s") vars'))
  ++ "\n"
  where
  si1 = spacingIndent
  vars' = vars_x $ length vars



tplPurescriptImports :: String -> String
tplPurescriptImports s = (intercalate "\n"
  [ ""
  , ""
  , "import Control.Monad.Aff"
  , "import Data.Argonaut.Combinators"
  , "import Data.Argonaut.Core"
  , "import Data.Argonaut.Decode"
  , "import Data.Argonaut.Encode"
  , "import Data.Argonaut.Printer"
  , "import Data.Date"
  , "import Data.Either"
  , "import Data.Foreign (readString)"
  , "import Data.Foreign.Class"
  , "import Data.JSON"
  , "import Data.List (List ())"
  , "import Data.Maybe"
  , "import Data.Set (Set ())"
  , "import Data.Tuple"
  , "import Network.HTTP.Affjax.Request"
  , "import Network.HTTP.Affjax.Response"
  , "import Optic.Lens"
  , "import Optic.Core"
  , "import Prelude"
  , ""
  , ""
  ]) ++ s



tplHaskellImports :: String -> String
tplHaskellImports s = (intercalate "\n"
  [ ""
  , ""
  , "import Data.Aeson"
  , ""
  , ""
  ]) ++ s



tplHeader :: String -> String -> String
tplHeader header s = header ++ "\n" ++ s



tplFooter :: String -> String -> String
tplFooter footer s = s ++ "\n" ++ footer



tplJObject :: Lang -> String
tplJObject LangPurescript = "JObject"
tplJObject LangHaskell    = "Object"
