getUsers :: Array (Tuple String String) -> ApiEff (Either ForeignError UserResponses)
getUsers params = getAt params [] ["users"]

getUsers' :: ApiEff (Either ForeignError UserResponses)
getUsers'  = getAt [] [] ["users"]

getUsers_ByUsersIds :: Array (Tuple String String) -> (Array  Int) -> ApiEff (Either ForeignError UserResponses)
getUsers_ByUsersIds params _ByUsersIds = getAt params [] ["users"]

getUsers_ByUsersIds' :: (Array  Int) -> ApiEff (Either ForeignError UserResponses)
getUsers_ByUsersIds' _ByUsersIds = getAt [] [] ["users"]

getUsers_ByUsersNames :: Array (Tuple String String) -> (Array  String) -> ApiEff (Either ForeignError UserResponses)
getUsers_ByUsersNames params _ByUsersNames = getAt params [] ["users"]

getUsers_ByUsersNames' :: (Array  String) -> ApiEff (Either ForeignError UserResponses)
getUsers_ByUsersNames' _ByUsersNames = getAt [] [] ["users"]

getUsers_ByUsersEmails :: Array (Tuple String String) -> (Array  String) -> ApiEff (Either ForeignError UserResponses)
getUsers_ByUsersEmails params _ByUsersEmails = getAt params [] ["users"]

getUsers_ByUsersEmails' :: (Array  String) -> ApiEff (Either ForeignError UserResponses)
getUsers_ByUsersEmails' _ByUsersEmails = getAt [] [] ["users"]

postUser :: Array (Tuple String String) -> UserRequest -> ApiEff (Either ForeignError UserResponse)
postUser params user_request = postAt params [] user_request ["user"]

postUser' :: UserRequest -> ApiEff (Either ForeignError UserResponse)
postUser' user_request = postAt [] [] user_request ["user"]

getUser :: Array (Tuple String String) -> Int -> ApiEff (Either ForeignError UserResponse)
getUser params user_id = getAt params [] ["user", show user_id]

getUser' :: Int -> ApiEff (Either ForeignError UserResponse)
getUser' user_id = getAt [] [] ["user", show user_id]

putUser :: Array (Tuple String String) -> Int -> UserRequest -> ApiEff (Either ForeignError UserResponse)
putUser params user_id user_request = putAt params [] user_request ["user", show user_id]

putUser' :: Int -> UserRequest -> ApiEff (Either ForeignError UserResponse)
putUser' user_id user_request = putAt [] [] user_request ["user", show user_id]

deleteUser :: Array (Tuple String String) -> Int -> ApiEff (Either ForeignError Unit)
deleteUser params user_id = deleteAt params [] ["user", show user_id]

deleteUser' :: Int -> ApiEff (Either ForeignError Unit)
deleteUser' user_id = deleteAt [] [] ["user", show user_id]
