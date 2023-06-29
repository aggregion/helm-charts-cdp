# test_agreements, t1_test_agreements, t2_test_agreements
CREATE TABLE table_1 (
  "id" Integer,
  "phone" String,
  "email" String,
  "name" String,
  "surname" String,
  "patronymic" String,
  "birth_date" String,
  "gender" String,
  "passport" String,
  "agreement" Integer
)
ENGINE = MergeTree
ORDER BY id
SETTINGS index_granularity = 8192
