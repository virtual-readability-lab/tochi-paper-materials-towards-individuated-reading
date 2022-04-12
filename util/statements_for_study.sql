### get all matchups
select *, user_type
from choices c 
inner join users u on u.id_user = c.id_user
where (u.user_type LIKE '%usertesting%' OR u.user_type LIKE '%csail%')
order by study_step desc, timestamp;
### 1566274562809

### get winning font per user
### need to edit to only grab users from a specific type
select *
from (select * from choices where bracket = 'final' order by timestamp desc)
group by id_user;

### raw wpm w/ re-read passage question
select s.*, mq.answer_num
from speed s
inner join miniq mq on mq.id_user = s.id_user and s.id_passage = mq.id_passage
where mq.question = 'reread_passage' and mq.study_step != 'training'

### raw wpm
select s.*, u.user_type
from speed s
inner join users u on u.id_user = s.id_user
where u.user_type LIKE '%mturk%';

### average words per minute
select s.font, avg(wpm) as wpm
from speed s
inner join users u on u.id_user = s.id_user
where s.font IS NOT NULL
and (u.user_type LIKE '%usertesting%' OR u.user_type LIKE '%csail%')
and (study_step != 'training')
group by font
order by wpm desc;

### font champs
select font, count(*) as ct, user_type
from fontchamps fc
inner join users u on u.id_user = fc.id_user
where (u.user_type LIKE '%usertesting%' OR u.user_type LIKE '%csail%')
AND study_step = 'final'
group by font, study_step
order by ct desc, font, user_type;


### wpm per interest in reading passage

select answer_num, avg(wpm) as wpm
from speed s 
inner join users u on u.id_user = s.id_user 
inner join (
    select * from miniq 
    where question = 'interest_in_passage' and study_step != 'training'
) mq on mq.id_user = s.id_user and mq.font = s.font

where (u.user_type LIKE '%usertesting%' OR u.user_type LIKE '%csail%') 
and s.study_step != 'training'
group by answer_num;


### font winner, speed, font familiarity, comprehension, passage familiarity, passage interest
### data other tab
select s.id_user, s.font, fc.champ, s.study_step, s.wpm, ff.font_fam, co.score, passage_fam, passage_int, s.user_type
from (
	select s.id_user, s.font, s.study_step, avg(wpm) as wpm, u.user_type
    from speed s 
    inner join users u on u.id_user = s.id_user 
	where (u.user_type LIKE '%usertesting%' OR u.user_type LIKE '%csail%') 
	and study_step != 'training'
    group by s.id_user, s.font
) s
left join (
    select id_user,font,1 as champ from fontchamps where study_step = 'final'
) as fc on fc.id_user = s.id_user and fc.font = s.font
left join (
	select id_user, font, answer_num as font_fam  from fontfamiliarity  group by id_user, font
) ff on ff.id_user = s.id_user and ff.font = s.font
left join (
	select id_user, font, ((sum(correct) *1.0)/ (count(*)*1.0)) as score from comprehension group by id_user, font
) as co on co.id_user = s.id_user and co.font = s.font
left join (
	select id_user, font, answer_num as passage_fam  from miniq where question LIKE '%familiarity%' group by id_user, font
) as f on f.id_user = s.id_user and f.font = s.font
left join (
	select id_user, font, answer_num as passage_int  from miniq where question LIKE '%interest%' group by id_user, font
) as i on i.id_user = s.id_user and i.font = s.font
order by s.id_user, s.study_step;


### font champ vs fastest font

select u.id_user, fontchamp.font as 'fontchamp', fontchamp.wpm, fastest.font as 'fastest', fastest.wpm,
CASE  WHEN fontchamp.font = fastest.font THEN 1 ELSE 0 END as preferred_is_fastest
from users u
inner join (
    select s.id_user, s.font, s.study_step, wpm 
    from (select * from fontchamps fc where study_step = 'final') as fc
    inner join (
        select id_user,font,avg(wpm) as wpm, study_step from speed s group by id_user, font order by wpm desc
    ) s on s.id_user = fc.id_user and s.font = fc.font
) as fontchamp on fontchamp.id_user = u.id_user

inner join (
    select s.id_user, s.font, s.study_step, wpm 
    from (
        select id_user,font,avg(wpm) as wpm, study_step from speed s group by id_user, font order by wpm desc
    ) s
    where study_step != 'training'
    group by s.id_user
) fastest on fastest.id_user = u.id_user

 where (u.user_type LIKE '%usertesting%' OR u.user_type LIKE '%csail%');


### did participants re-read passages
select id_user, answer, count(*) as ct
from miniq
where question = 'reread_passage' and answer = 'yes'
group by id_user, answer
order by ct desc;


### font normalization

select n.*, u.user_type
from normalization n 
inner join (select id_user, count(*) c from normalization group by id_user having c = 20) nn on nn.id_user = n.id_user
inner join users u on u.id_user = n.id_user;

select n.id_user, u.user_type, font, normalization, count(*) as ct 
from normalization n inner join users u on u.id_user = n.id_user
group by n.id_user
having ct = 20;

select font, normalization, count(*) as ct 
from normalization n 
inner join (select id_user, count(*) c from normalization group by id_user having c = 20) nn on nn.id_user = n.id_user
group by font, normalization;

select n.id_user, normalization, count(*) as ct 
from normalization n inner join users u on u.id_user = n.id_user
where u.user_type = 'readability_csail' 
group by n.id_user, normalization;

select normalization, count(*) as ct 
from normalization n inner join users u on u.id_user = n.id_user
where u.user_type = 'readability_csail'
group by normalization;

 ### insert passages

INSERT INTO passages (id_passage, source, pdf_corpus1, pdf_corpus2, passage1, passage2, passage3, passage4, question1, choice1_q1, choice2_q1, choice3_q1, answer_q1, question2, choice1_q2, choice2_q2, choice3_q2, answer_q2, question3, choice1_q3, choice2_q3, choice3_q3, answer_q3)
VALUES(6,"https://docs.google.com/document/d/19ySFD7FLJ-1zn6XR0DuapULnF3xesD8CsNzpIfr6F_M/edit","Nature","","We all look different. Some of us are short, some of us are tall. Some of us have big feet, some of us have small feet. Even though we all look different, our bodies are all made up of the same things. First, we have bones. Our bones give us shape. Because bones don’t bend, we are able to stand up. The bones move our joints, the places where they come together. ","Muscles are fastened to our bones. They make us strong and able to move. Our muscles have nerves, tiny cells that send messages to our brain telling it which part of our body to move. We are all covered by our skin. Our skin protects us. Our skin is waterproof, and it keeps our bodies cool by letting us sweat.","","","Our skin","Makes us strong","Protects us","Helps us breathe","Protects us","Our bones","Are really light","Are really strong","Don’t bend","Don’t bend","","","","",""),
INSERT INTO passages (id_passage, source, pdf_corpus1, pdf_corpus2, passage1, passage2, passage3, passage4, question1, choice1_q1, choice2_q1, choice3_q1, answer_q1, question2, choice1_q2, choice2_q2, choice3_q2, answer_q2, question3, choice1_q3, choice2_q3, choice3_q3, answer_q3)
VALUES(7,"https://docs.google.com/document/d/19ySFD7FLJ-1zn6XR0DuapULnF3xesD8CsNzpIfr6F_M/edit","Poetry","","Have you ever seen the moon shining bright on a dark night? Have you ever wondered just who or what is out when the moon is out? The moon has a face like a clock on the wall; She shines on thieves on the garden stall, On streets and fields and harbor quays And birdies asleep in the branches of trees","The squealing cat and the squeaking mouse. The howling dog by the backdoor of the house. The black bat that lies in its bed till noon. All love to be out at night in the light of the moon. But of all the things that belong to the day, Cuddle to sleep to be out of her way; And flowers and children close their eyes, Till up in the morning the sun shall rise.","","","According to the poem, the moon","Likes being out at night","Does not like being out at night","The poem does not actually say how the moon feels at all","The poem does not actually say how the moon feels at all","The poem says that the moon’s face is like","A clock","Cheese","A person's face","A clock","","","","",""),
VALUES(8,"https://docs.google.com/document/d/19ySFD7FLJ-1zn6XR0DuapULnF3xesD8CsNzpIfr6F_M/edit","HowTo/Topic","","Did you know you can make your own dish soap right at home without having to go to the store? Directions:  you can make your own liquid dish soap in just a few easy steps.  Use a bar of soap that is made from natural ingredients.  Take a vegetable peeler, like the one your mom or dad, or even you might use to peel potatoes.  Peel the soap into a small saucepan on the top of your stove.","When done peeling the soap into the small saucepan, heat the soap pieces on low heat for about two hours.  After two hours, remove the saucepan from the stove, turn off the stove and let the mixture cool down.  When it is cool, just pour it into a tupperware container, or bowl.  Now you are ready to use your homemade soap to wash your dishes. Amazing.","","","In order to make your own soap, just use a vegetable peeler and peel it into a","Saucepan","Paper bag","Bottle","Saucepan","When the soap is melted remove it from the stove and","Put it in the refrigerator","Let it cool down","Put it in the freezer","Let it cool down","","","","",""),
VALUES(9,"https://docs.google.com/document/d/19ySFD7FLJ-1zn6XR0DuapULnF3xesD8CsNzpIfr6F_M/edit","Nature","","The deer took a good, long look at himself in the water of the lake. “My, how handsome my antlers are,” he thought. “They are so long, and curved and wide.” But then he noticed his thin, stick like legs he was not so happy. In fact he thought that his legs were very ugly. While the deer was looking in the water, a lion was secretly watching him. The lion thought that the deer looked nice and tasty. “Just right for dinner,” the lion thought to herself.","When the deer saw the lion, the deer ran very fast. But the deer’s antlers got caught in the branches of a tree. Just as the lion was about to jump on the deer, the deer got his antlers free and ran like the wind. Safe at last, the deer said to himself, “how silly I was. I thought my antlers were so handsome and wonderful, but they almost got me eaten by the lion. And my legs, which I thought were so ugly, saved my life.”","","","The deer looked at himself in","A mirror","A window","The water","The water","The lesson of this story is","Lions don’t know how to catch a deer","Looks are not always the most important thing","Everyone should have thin legs","Looks are not always the most important thing","","","","",""),
VALUES(10,"https://docs.google.com/document/d/1X6BqOO0y0MnR1YNmE-RUMboCfXsfso_zA6lbQv4Hr0s/edit","HowTo/Topic","","If you have ever been camping, then you might have made a roaring campfire to cook on or to stay warm. The right way to put out a fire is to sprinkle it with water. Splash the water on the fire with your hand. Don’t pour water on the fire. A solid stream of water sometimes leaves a small part of the fire hot and still burning. Next, take a stick and stir the embers or hot parts of the fire around.","Then sprinkle the fire again with water, making sure to get all parts of the area that is hot and was burning. Before you leave the fire, you should check it one more time by putting your hand over the ashes. After the wet ashes have cooled off, you should bury them in the dirt. If you have to put out a fire and don’t have any water, you can just use plain sand, dirt, or soil to put out the fire.","","","Do not pour a steady stream of water on the fire because this","May leave some ashes still burning or hot","Creates a lot steam","Can cause hot embers to get out","May leave some ashes still burning or hot","After you first sprinkle water on the fire, you should","Touch it","Sprinkle water again","Wait","Sprinkle water again","","","","",""),
VALUES(11,"https://docs.google.com/document/d/1X6BqOO0y0MnR1YNmE-RUMboCfXsfso_zA6lbQv4Hr0s/edit","Nature","","Just about everybody has heard the crash, bang, and boom of a lightning storm. Sometimes it sounds far away, and sometimes it sounds like it’s right over your head. Have you wondered how far away it really is? Sound travels about one mile in five seconds. That’s pretty fast. Light travels much more quickly than sound.","When you see a flash of lightning during a storm, begin to slowly count, saying one-one thousand, two-one thousand, and so on. Keep counting until you hear the thunder that goes with the lightning strike. If you reached five, the lightning and the storm are one mile away. If you reached ten, they are two miles away.","","","The passage tells you how to","Keep safe during a storm","Look at lighting","Figure out how far away the storm really is","Figure out how far away the storm really is","If you count to ten means that the lightning and storm are","Right over your head","Two miles away","One mile away","Two miles away","Two miles away","","","",""),
VALUES(12,"https://docs.google.com/document/d/1X6BqOO0y0MnR1YNmE-RUMboCfXsfso_zA6lbQv4Hr0s/edit","HowTo/Topic","","Have you ever watched people dive into a pool? There are all kinds of different types of dives. One dive is called a swan dive. The swan dive can be beautiful if it is done right. The swan dive is an up-and-out, gliding kind of a dive. Just after reaching the high point of your dive, try to put your body in a birdlike position. Put your arms out sideways with the palms of your hands facing down. ","Arch your back slightly and then tilt your head back. You will look and feel like a bird diving into the water. Stay in this position for almost the entire dive. Then just a split second before you enter the water, quickly bring your arms forward in front of your head. It’s important to finish the dive right, so make sure to keep your legs straight, closed, and stiff.","","","During most of the dive, your arms should be","By your side","Folded at your chest","Forward in front of your head","By your side","Just before you enter the water, bring your arms","Forward in front of your head","To your chin","By your side","Forward in front of your head","","","","",""),
VALUES(13,"https://docs.google.com/document/d/1X6BqOO0y0MnR1YNmE-RUMboCfXsfso_zA6lbQv4Hr0s/edit","HowTo/Topic","","Everyone knows that swimming is a ton more fun when you follow the rules of water safety. First, learn how to swim. You can learn how to swim from a family member like a parent or brother or sister. You can also take swimming lessons from someone who knows how to swim. Kind of like going to school, but it’s a swimming school. No matter where you choose to swim, either a lake, pool or the ocean you should always make sure that there is a lifeguard around.","It’s not a good idea to swim in a lake, pond, pool, or the ocean if there is not a lifeguard nearby. Always try to swim with a buddy or a friend. Keep your eye on your buddy or friend and make sure they keep an eye out for you. That way you’re both watching one another. Finally, when you are learning how to swim, stay in the shallow water whenever possible.","","","When swimming with another person or buddy always keep your eyes on your ","Cell phone","Water","Buddy","Buddy","These directions were written to teach you how to","Choose a swimming buddy        ","Be safe in the water","Swim","Be safe in the water","","","","",""),
VALUES(14,"https://docs.google.com/document/d/1X6BqOO0y0MnR1YNmE-RUMboCfXsfso_zA6lbQv4Hr0s/edit","HowTo/Topic","","Have you ever had to lift a heavy box off of the floor? It can be very hard, and you could possibly hurt your back. Imagine that you have to pick up a really heavy box from the floor. Like just about anything you do, there is a correct way and a wrong way to do this. There is a correct way to lift heavy things from the floor without hurting yourself. First, bend your knees and squat down. Try to keep your back as straight as possible. ","Try not to bend over from the waist as you are trying to pick up the heavy box. Bending from the waist puts a lot of pressure on your lower-back muscles. Try to get as close to the box as you can. To do this you just might have to spread your knees or even lower one knee. Keep the box close to your body. Once you have the box in your hands, just use the muscles in your legs to stand up straight.","","","When lifting things that are heavy it is important to","Keep the object close to your body","Bend your elbows properly","Use your knees","Keep the object close to your body","Before you lift a heavy object like a box you may have to","Wash your hands","Lower one knee","Stretch","Lower one knee","","","","",""),
VALUES(15,"https://docs.google.com/document/d/1X6BqOO0y0MnR1YNmE-RUMboCfXsfso_zA6lbQv4Hr0s/edit","HowTo/Topic","","Have you had a time when you run the water in the bathtub, your bathroom sink, or the kitchen sink and the water just won’t go down the drain? Or it seems to take forever to go down the drain? Well, if you are having trouble with a blocked drain you may just be able to save some money by following these simple directions before you call for the plumber, who is trained to help people unblock their drains. ","Go to the store and buy some baking soda and vinegar. Put a handful of baking soda down the blocked drain. After that add a half of a cup of the vinegar. Cover the drain tightly for about a minute. After a minute you might just be happy to learn that the drain is no longer blocked and works like a charm. The drain is no longer blocked.","","","The only two things you will need to clean your blocked drain are","Salt and pepper","Vinegar and baking soda","Plunger and pipe cleaner","Vinegar and baking soda","You only need to cover the drain for","A day","A minute","30 minutes","A minute","","","","",""),
VALUES(16,"https://docs.google.com/document/d/1X6BqOO0y0MnR1YNmE-RUMboCfXsfso_zA6lbQv4Hr0s/edit","HowTo/Topic","","Believe it or not, there is a right way to do push-ups which make them easier to do. In order to do a push-up the right way, you should lie on the floor, face down. Keep your legs together. Put your hands on the floor beside your shoulders. Point your fingers straight ahead. After you do this, straighten your arms to push your body off the floor. ","Your weight should be on your hands and toes. Try not to let your stomach sag so that it is close to the floor. Don’t arch your back like a cat does when it is mad. You have to try to keep your body straight. Lower your body until your chest is barely touching the floor. Finally, push yourself right up again without any delay or rest. Keep repeating the exercise until you are done.","","","When doing a push-up it is important to","Curl up","Keep your body straight","Use your hands","Keep your body straight","Your weight should be on your","Hands and toes","Arms","Back","Hands and toes","","","","",""),
VALUES(17,"https://docs.google.com/document/d/1X6BqOO0y0MnR1YNmE-RUMboCfXsfso_zA6lbQv4Hr0s/edit","HowTo/Topic","","Here’s how to make the best tuna fish sandwich in the neighborhood, maybe the entire galaxy! Go to the grocery store and buy a 9 ounce can of tuna fish, celery, onions, pita bread, and mayonnaise or salad dressing. Using a spoon, spoon half the tuna in the can into a bowl. Get some celery and onions and chop them up with a knife. When done chopping the celery and onions mix them with mayonnaise or salad dressing in a large bowl.","Cut the sides off two slices of the pita bread so that each piece has an open pocket. Toast the pita bread pockets until they are warm. Don’t over toast the pita pockets or you might burn them. Fill the pita pockets with the mixed up tuna. Eat one yourself to see how yummy it is and then give one to a friend. Pretty soon the entire neighborhood will be knocking at your door to eat your yummy tuna fish sandwiches.","","","You have to mix the tuna fish with","Mayonnaise or salad dressing, pickles, and onions","Mayonnaise or salad dressing, celery, and onions","Mayonnaise or salad dressing, cucumbers, and celery","Mayonnaise or salad dressing, celery, and onions","Before you fill the pockets of your pita bread with the tuna mixture","Lightly toast the pita bread but don’t burn it","Warm it up in the microwave","Heat it up on a frying pan","Lightly toast the pita bread but don’t burn it","","","","","");