# Датасет 2
# Выполнить у каждого провайдера для таблиц: t2_test_agreements

insert into t2_test_agreements (id, name, surname, patronymic, birth_date, gender, passport, phone, email, agreement)
SELECT toInt32(number) as id,
concat('name_', toString(number)) AS name,
concat('surname_', toString(number)) as surname,
concat('patronymic_', toString(number)) as patronymic,
concat('birth_date_', toString(number)) as birth_date,
number % 2 as gender,
concat('passport_', toString(number)) as passport,
concat('phone_', toString(number)) as phone,
concat('email_', toString(number)) as email,
0 as agreement
FROM numbers(1, 100);
