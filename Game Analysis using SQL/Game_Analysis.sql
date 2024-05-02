
use Game_analysis;

-- Problem Statement - Game Analysis dataset
-- 1) Players play a game divided into 3-levels (L0,L1 and L2)
-- 2) Each level has 3 difficulty levels (Low,Medium,High)
-- 3) At each level,players have to kill the opponents using guns/physical fight
-- 4) Each level has multiple stages at each difficulty level.
-- 5) A player can only play L1 using its system generated L1_code.
-- 6) Only players who have played Level1 can possibly play Level2 
--    using its system generated L2_code.
-- 7) By default a player can play L0.
-- 8) Each player can login to the game using a Dev_ID.
-- 9) Players can earn extra lives at each stage in a level.

-- pd (P_ID,PName,L1_status,L2_Status,L1_code,L2_Code)
-- ld (P_ID,Dev_ID,start_time,stages_crossed,level,difficulty,kill_count,
-- headshots_count,score,lives_earned)


-- Q1) Extract P_ID,Dev_ID,PName and Difficulty_level of all players at level 0 ?
select P.P_ID, P.PName, LD.Dev_ID, LD.Difficulty, LD.Level
from player_details as P
join level_details2 as LD ON P.P_ID = LD.P_ID
where LD. Difficulty = "Medium" And LD.Level = 0;

-- Q2) Find Level1_code wise Avg_Kill_Count where lives_earned is 2 and atleast 3 stages are crossed ?
select P.L1_code as Level, avg(LD.Kill_Count) AS Avg_Kill_Count
from level_details2 as LD
join player_details as P on P.P_ID = LD.P_ID
where LD.Lives_Earned = 2 
group by P.L1_code
having count(distinct stages_crossed) >= 3;

-- Q3) Find the total number of stages crossed at each diffuculty level where for Level2 with players use zm_series devices. Arrange the result in decsreasing order of total number of stages crossed.
select Difficulty, level, sum(Stages_crossed) as Total_stages_crossed
from level_details2 as LD
join player_details as P on P.P_ID = LD.P_ID
where LD.level = 2 and LD.Dev_ID Like '%zm%'
group by Difficulty
order by Total_stages_crossed desc;

-- Q4) Extract P_ID and the total number of unique dates for those players who have played games on multiple days.
select P_ID, count(distinct TimeStamp) as total_Dates
from level_details2
group by P_ID
having count(distinct TimeStamp) > 1;
 
-- Q5) Find P_ID and level wise sum of kill_counts where kill_count is greater than avg kill count for the Medium difficulty.
select P_ID, Level, sum(kill_count) as Total_kill_counts
from level_details2 
where kill_count > (
select avg(kill_count)
from level_details2 as LD
join player_details as P on LD.P_ID = P.P_ID
where LD.Difficulty = "medium"
)
group by P_ID, Level;


-- Q6)  Find Level and its corresponding Level code wise sum of lives earned excluding level 0. Arrange in asecending order of level.
select LD.Level as level, P.L1_Code as Level_code,  P.L2_code as level2_code, sum(LD.Lives_Earned) as Total_lives
from player_details as P
join level_details2 as LD on LD.P_ID = P.P_ID
where LD.Level >= 0
group by LD.Level, P.L1_code, P.L2_code
order by LD.Level asc;


-- Q7) Find Top 3 score based on each dev_id and Rank them in increasing order using Row_Number. Display difficulty as well. 
select Dev_ID, Score, Difficulty, ranking
from (
select Dev_ID, Score, Difficulty, row_number() over(partition by Dev_ID order by Score desc) as ranking
from level_details2
where Dev_id is not null
 and Score is not null
 and Difficulty is not null
)as rank_score
where ranking <=3
order by Dev_ID, Difficulty;

-- Q8) Find first_login datetime for each device id
select Dev_ID, min(Timestamp) as first_login
from level_details2
group by Dev_id;

-- Q9) Find Top 5 score based on each difficulty level and Rank them in increasing order using Rank. Display dev_id as well.
select Dev_ID, Score, Difficulty, ranking
from (
select Dev_id, Score, Difficulty, rank() over(partition by Difficulty order by Score asc) as ranking
from level_details2
where Dev_id is not null and Score is not null and Difficulty is not null
)as rank_score
where ranking >= 5
order by Dev_ID, Difficulty;

-- Q10) Find the device ID that is first logged in(based on start_datetime) for each player(p_id). Output should contain player id, device id and first login datetime.
select LD.P_ID, LD.Dev_ID, LD.TimeStamp as first_login
from level_details2 as LD
join(
select P_ID, min(TimeStamp) as f_login
from Level_details2
group by P_ID
)
as f_login_per_player on LD.P_ID = f_login_per_player.P_ID
and LD.TimeStamp = f_login_per_player.f_login
order by first_login asc;
    
-- Q11) For each player and date, how many kill_count played so far by the player. That is, the total number of games played by the player until that date.
-- a) window function
select P.P_ID,P.PNAME,TimeStamp, sum(Kill_count) over(partition by PNAME order by TimeStamp) as Total_kill_count
from player_details as P
join Level_details2 as LD on P.P_ID = LD.P_ID
order by Total_kill_count desc;

-- b) without window function
select P.P_ID,P.PNAME,LD.TimeStamp,
(select sum(LD2.Kill_count)
from Level_details2 as LD2
where LD2.P_ID = P.P_ID and LD2.TimeStamp >= LD.TimeStamp 
) as kill_count
from player_details as p
join level_details2 as LD on P.P_ID = LD.P_ID
order by kill_count desc;

-- Q12) Find the cumulative sum of stages crossed over a start_datetime 
select Stages_crossed, TimeStamp, sum(Stages_crossed) over(order by TimeStamp desc) as Cumulative_Stages
from level_details2;

-- Q13) Find the cumulative sum of an stages crossed over a start_datetime for each player id but exclude the most recent start_datetime
select P_ID, TimeStamp, Stages_crossed, sum(Stages_crossed) over(partition by P_ID order by TimeStamp) as Cumulative_Stages_crossed
from Level_details2
where TimeStamp < (select max(TimeStamp)
from Level_details2 as LD
where LD.P_ID = level_details2.P_ID
);

-- Q14) Extract top 3 highest sum of score for each device id and the corresponding player_id
select P_ID, Dev_ID, sum(Score) as Total_score
from Level_details2
group by P_ID,Dev_ID
order by Dev_ID, Total_score desc
limit 5;

-- Q15) Find players who scored more than 50% of the avg score scored by sum of scores for each player_id
select P_ID, sum(score) as ToTal_score
from level_details2
group by P_ID
having sum(Score) > 0.5 * (
select avg(sum_score) from (select sum(score) as Sum_Score 
from Level_details2 
group by P_ID) as avg_score
);


-- Q16) Create a stored procedure to find top n headshots_count based on each dev_id and Rank them in increasing order using Row_Number. Display difficulty as well.
delimiter //
create procedure TopNotchHeadshot(in n int)
begin
	declare n int;
	set n = 5;
	select Dev_ID, Headshot_Count, Difficulty, rank
	from (
			select Dev_ID, Headshot_Count, Difficulty,
		Row_number() over(partition by Dev_ID order by Headshot_Count) 
		from Level_details2) as rank
    where rank <= n 
    order by Dev_ID, Headshot_count
end //
delimiter;

-- Q17) Create a function to return sum of Score for a given player_id. 
delimiter //
drop function if exists Total_score;
create function Total_Score(P_ID int)
returns int
reads sql data
begin 
declare Total int;
    select sum(Score) into Total
    from Level_details2
    where P_ID = Total_Score.P_ID;
    return Total;
end //
delimiter ;