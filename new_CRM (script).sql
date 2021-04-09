#Задача_1: Найти менеджеров из таблицы Employees, которые обработали больше всего заказов 

SELECT
ord.Work_for_Employee,
ord.Status, 
emp.idEmployees,
COUNT(emp.idEmployees) AS orders_amount
FROM new_CRM.Orders ord
JOIN new_CRM.Employees emp ON emp.idEmployees = ord.Work_for_Employee
WHERE Status = 1
GROUP BY emp.idEmployees 
ORDER BY orders_amount DESC;

#Менеджер с id 38 обработал максимальное число заказов - 4 

#Задача_2: Получить среднюю длительность обработки заказов по каждому статусу 

SELECT 
ROUND(AVG(DATEDIFF (Finished_at, Created_at)), 0) AS Order_Duration
FROM new_CRM.Orders
WHERE Status = 1
UNION 
SELECT ROUND(AVG(DATEDIFF (Finished_at, Created_at))) AS Order_Duration
FROM new_CRM.Orders
WHERE Status = 0
UNION 
SELECT ROUND(AVG(DATEDIFF (Finished_at, Created_at))) AS Order_Duration
FROM new_CRM.Orders
WHERE Status = -1;

# Задача_3. Посчитать кол-во заказов каждого клиента, которому консультанты 
# направляли сообщения 

SELECT
ord.Ordered_by_Client,
COUNT(ord.idOrders) AS amount
FROM new_CRM.Orders ord
/*JOIN new_CRM.Products prod ON prod.ID = ord.Ordered_Product*/
JOIN new_CRM.Message M ON M.To_Client = ord.Ordered_by_Client
GROUP BY ord.Ordered_by_Client
ORDER BY amount

# Задача_4. По клиентам, которые делали заказы и которым направляли сообщения, посмотреть 
# типы выбранных продуктов, имя и фамилию консульантов, которые писали сообщения
# клиентам, начиная с 7 июля 2007 года 

SELECT
ord.Ordered_by_Client,
M.idMessage,
(SELECT DATE (M.Created_at)) AS Message_Date,
prod.ID AS Product_ID,
prod.Type, 
emp.idEmployees AS Manager,
CONCAT(emp.Name, ' ', emp.Surname) AS Manager_Name
FROM new_CRM.Orders ord
JOIN new_CRM.Products prod ON prod.ID = ord.Ordered_Product
JOIN new_CRM.Message M ON M.To_Client = ord.Ordered_by_Client
JOIN new_CRM.Employees emp ON emp.idEmployees = M.From_Employees_idEmployees
WHERE ((SELECT DATE (M.Created_at)) BETWEEN '2007-07-07 %' AND NOW())
ORDER BY Message_Date DESC;

# Задача_4.1. И вывести топ-10 менеджеров, которые написали больше всего сообщений 
#клиентам за весь период

SELECT
emp.idEmployees AS Manager,
CONCAT(emp.Name, ' ', emp.Surname) AS Manager_Name,
COUNT(M.idMessage) AS Message_amount
FROM new_CRM.Orders ord
JOIN new_CRM.Products prod ON prod.ID = ord.Ordered_Product
JOIN new_CRM.Message M ON M.To_Client = ord.Ordered_by_Client
JOIN new_CRM.Employees emp ON emp.idEmployees = M.From_Employees_idEmployees
GROUP BY Manager
ORDER BY Message_amount DESC
LIMIT 10;


 # Создание процедуры 

 CREATE DEFINER=`root`@`localhost` PROCEDURE `new_client_company`(
IN i_Website VARCHAR(255),
OUT result VARCHAR(255)
)
BEGIN
	DECLARE `_rollback` BIT DEFAULT 0;
    DECLARE error_code VARCHAR(255);
    DECLARE error_text VARCHAR(255);
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET STACKED DIAGNOSTICS CONDITION 1
			error_code = RETURNED_SQLSTATE, error_text = MESSAGE_TEXT;
		SET `_rollback` = 1;
        SET result = CONCAT('[', error_code, '] ', error_text);
    END;
    
	START TRANSACTION;
		INSERT INTO `new_CRM`.`Clients_Companies`
		(website)
		VALUES
		(i_Website);
		

	IF `_rollback` = 1 THEN
		ROLLBACK;
    ELSE
		SET result = 'ok';
		COMMIT;
	END IF;
END

# Создание триггера

CREATE DEFINER = CURRENT_USER TRIGGER `new_CRM`.`Clients_Contacts_Info_BEFORE_INSERT` BEFORE INSERT ON `Clients_Contacts_Info` FOR EACH ROW
BEGIN
IF NEW.Company IS NULL AND NEW.Position IS NULL THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'not valid';
END IF;
END


