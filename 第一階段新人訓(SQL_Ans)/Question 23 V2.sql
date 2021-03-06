declare @mytable table(EmployeeID int,ManagerID int,Salary int)  --宣告一個暫存表格mytable 

--Part1 把大主管的EmployeeID和調薪後的薪水加入mytable 

insert into @mytable
-- 如果調薪後薪水筆比原薪水多5000以上，最多調5000，否則依照調薪的薪水
select e.EmployeeID,e.ManagerID, case when (big.newsal - e.salary) >= 5000 then e.salary+5000
							else  big.newsal end salary 
							
from Employees e, -- 如果處理筆數介於50到99之間則調薪1.05倍，如果處理筆數大於100則調薪1.1倍
				(select EmployeeID,case when bigmanager.ordercount between 50 and 99 then Salary *1.05
												when bigmanager.ordercount >=100 then Salary *1.10
												else Salary
												end newsal
				from Employees,   --查處理超過50筆的大主管的id和筆數
								(select e.EmployeeID as empid ,count(o.OrderID) as ordercount
								from Employees e ,Orders o
								where e.EmployeeID = o.EmployeeID and e.ManagerID is null
								group by e.EmployeeID
								having count(o.OrderID)>=50 
								) bigmanager    
				where Employees.EmployeeID = bigmanager.empid)big 
where e.EmployeeID = big.EmployeeID
----------------------------------------------------------------------------------------------------------------------------------------------
-- Part2 把小主管的EmployeeID和調薪後的薪水加入mytable 
insert into @mytable
-- 如果調薪後薪水比大主管多則薪水最多調成跟大主管一樣
select  distinct middle.EmployeeID, middle.ManagerID,case when middlesal>mytable.Salary then mytable.Salary
							  when middlesal>Employees.Salary and mytable.Salary is null then Employees.Salary	
							  else middlesal
							  end newmiddlesal 					
from @mytable mytable right JOIN	-- 如果調薪後薪水筆比原薪水多5000以上，最多調5000，否則依照調薪的薪水
					(select e.EmployeeID, e.Salary , e.ManagerID,case when (middle.newsal- e.Salary)>=5000 then e.Salary+5000
														 else  middle.newsal
														 end middlesal	
					from Employees e,    -- 如果處理筆數介於50到99之間則調薪1.05倍，如果處理筆數大於100則調薪1.1倍	
									(select e1.EmployeeID ,salary ,case when middlemanager.ordercount between 50 and 99 then Salary *1.05
																	when middlemanager.ordercount >=100 then Salary *1.10
																	else Salary
																	end newsal
											
									from Employees e1, --查處理超過50筆的主管的id和筆數，且他主管是大主管
													(select e.EmployeeID empid ,count(o.OrderID)ordercount 
													from Employees e ,Orders o							  --查出主管id是null的所有員工id，且薪水小於大主管
													where e.EmployeeID = o.EmployeeID and e.EmployeeID in(select worker.EmployeeID
																										  from Employees worker ,Employees manager
																										  where worker.ManagerID = manager.EmployeeID and manager.ManagerID is null and manager.Salary>=worker.Salary)
													group by e.EmployeeID
													having count(o.OrderID)>=50) middlemanager
									where e1.EmployeeID = middlemanager.empid) middle
					where e.EmployeeID = middle.EmployeeID) middle
on mytable.EmployeeID =middle.ManagerID  
right JOIN Employees
on Employees.EmployeeID =middle.ManagerID 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--把員工的EmployeeID和調薪後的薪水加入mytable 
insert into @mytable
--如果調薪後薪水比小主管多則薪水最多調成跟小主管一樣
select distinct newemp.EmployeeID,mytable.EmployeeID,case when empsal >mytable.Salary then mytable.Salary
			when empsal >Employees.Salary and mytable.Salary is null then Employees.Salary	
			else empsal
			end empsal2	
from @mytable mytable  right JOIN-- 如果調薪後薪水筆比原薪水多5000以上，最多調5000，否則依照調薪的薪水		 
				(select e.EmployeeID , e.Salary ,e.ManagerID, case when (newsal -e.Salary)>5000  then e.Salary+5000
															 else newsal
															 end empsal	
				from Employees e,  -- 如果處理筆數介於50到99之間則調薪1.05倍，如果處理筆數大於100則調薪1.1倍
								(select e.EmployeeID , e.Salary ,case when ordercount between 50 and 99 then e.Salary*1.05
																	  when ordercount >=100 then	e.Salary*1.1
																	  else e.Salary
																	  end newsal						
								from Employees e,
												(select e.EmployeeID,COUNT(o.OrderID) ordercount --查出處理訂單數量>=50筆的員工
												from Orders o , Employees e
												where o.EmployeeID  = e.EmployeeID and  e.EmployeeID  in (
																										select e.EmployeeID
																										from Employees e,
																										(select worker.EmployeeID,worker.Salary
																										  from Employees worker ,Employees manager
																										  where worker.ManagerID = manager.EmployeeID and manager.ManagerID is null and manager.Salary>=worker.Salary) middlemanager
																										  where e.ManagerID = middlemanager.EmployeeID and e.Salary<=middlemanager.Salary
																										  )																							
												group by  e.EmployeeID
												having COUNT(o.OrderID)>=50) empcount
								where e.EmployeeID = empcount.EmployeeID) emp
				where e.EmployeeID = emp.EmployeeID) newemp
on mytable.EmployeeID = newemp.ManagerID right JOIN Employees
on Employees.EmployeeID = newemp.ManagerID

-----修改員工薪水
update Employees set Salary = mytable.Salary
from Employees join @mytable mytable
on Employees.EmployeeID = mytable.EmployeeID 