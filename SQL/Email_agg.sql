/****** Object:  StoredProcedure [dbo].[email_aggregation]    Script Date: 5/11/2020 8:41:31 AM ******/
SET ANSI_NULLS ON GO
SET QUOTED_IDENTIFIER ON GO -- =============================================
-- Author:      <Author, , Name>
-- Create Date: <Create Date, , >
-- Description: <Description, , >
-- =============================================

ALTER PROCEDURE [dbo].[email_aggregation] AS BEGIN -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.

SET NOCOUNT ON -- Insert statements for procedure here

DROP TABLE IF EXISTS email_agg
SELECT ContactId,
       MessageId INTO #sent_step1
FROM emailsent
GROUP BY ContactId,
         MessageId;


SELECT #sent_step1.MessageId AS sent_email,
       contact.gendercode AS sent_gender,
       contact.fm_age AS sent_age,
       count(#sent_step1.ContactId) AS sent_n INTO #email_sent_agg
FROM #sent_step1
LEFT JOIN contact ON UPPER(#sent_step1.ContactId) = CAST(contact.Id AS VARCHAR(36))
GROUP BY #sent_step1.MessageId,
         contact.gendercode,
         contact.fm_age
ORDER BY #sent_step1.MessageId,
         contact.gendercode,
         contact.fm_age;


SELECT ContactId,
       MessageId INTO #sent_delivered1
FROM emaildelivered
GROUP BY ContactId,
         MessageId;


SELECT #sent_delivered1.MessageId AS delivered_email,
       contact.gendercode AS delivered_gender,
       contact.fm_age AS delivered_age,
       count(#sent_delivered1.ContactId) AS delivered_n INTO #email_delivered_agg
FROM #sent_delivered1
LEFT JOIN contact ON UPPER(#sent_delivered1.ContactId) = CAST(contact.Id AS VARCHAR(36))
GROUP BY #sent_delivered1.MessageId,
         contact.gendercode,
         contact.fm_age
ORDER BY #sent_delivered1.MessageId,
         contact.gendercode,
         contact.fm_age;


SELECT ContactId,
       MessageId INTO #sent_hardbounced1
FROM emailhardbounced
GROUP BY ContactId,
         MessageId;


SELECT #sent_hardbounced1.MessageId AS hardbounced_email,
       contact.gendercode AS hardbounced_gender,
       contact.fm_age AS hardbounced_age,
       count(#sent_hardbounced1.ContactId) AS hardbounced_n INTO #email_hardbounced_agg
FROM #sent_hardbounced1
LEFT JOIN contact ON UPPER(#sent_hardbounced1.ContactId) = CAST(contact.Id AS VARCHAR(36))
GROUP BY #sent_hardbounced1.MessageId,
         contact.gendercode,
         contact.fm_age
ORDER BY #sent_hardbounced1.MessageId,
         contact.gendercode,
         contact.fm_age;


SELECT ContactId,
       MessageId INTO #sent_blocked1
FROM emailblocked
GROUP BY ContactId,
         MessageId;


SELECT #sent_blocked1.MessageId AS blocked_email,
       contact.gendercode AS blocked_gender,
       contact.fm_age AS blocked_age,
       count(#sent_blocked1.ContactId) AS blocked_n INTO #email_blocked_agg
FROM #sent_blocked1
LEFT JOIN contact ON UPPER(#sent_blocked1.ContactId) = CAST(contact.Id AS VARCHAR(36))
GROUP BY #sent_blocked1.MessageId,
         contact.gendercode,
         contact.fm_age
ORDER BY #sent_blocked1.MessageId,
         contact.gendercode,
         contact.fm_age;


SELECT ContactId,
       MessageId INTO #sent_opened1
FROM emailopened
GROUP BY ContactId,
         MessageId;


SELECT #sent_opened1.MessageId AS opened_email,
       contact.gendercode AS opened_gender,
       contact.fm_age AS opened_age,
       count(#sent_opened1.ContactId) AS opened_n INTO #email_opened_agg
FROM #sent_opened1
LEFT JOIN contact ON UPPER(#sent_opened1.ContactId) = CAST(contact.Id AS VARCHAR(36))
GROUP BY #sent_opened1.MessageId,
         contact.gendercode,
         contact.fm_age
ORDER BY #sent_opened1.MessageId,
         contact.gendercode,
         contact.fm_age;


SELECT ContactId,
       MessageId INTO #sent_clicked1
FROM emailclicked
GROUP BY ContactId,
         MessageId;


SELECT #sent_clicked1.MessageId AS clicked_email,
       contact.gendercode AS clicked_gender,
       contact.fm_age AS clicked_age,
       count(#sent_clicked1.ContactId) AS clicked_n INTO #email_clicked_agg
FROM #sent_clicked1
LEFT JOIN contact ON UPPER(#sent_clicked1.ContactId) = CAST(contact.Id AS VARCHAR(36))
GROUP BY #sent_clicked1.MessageId,
         contact.gendercode,
         contact.fm_age
ORDER BY #sent_clicked1.MessageId,
         contact.gendercode,
         contact.fm_age;


SELECT * INTO #email_agg
FROM #email_sent_agg AS a
FULL OUTER JOIN #email_delivered_agg AS b ON a.sent_email = b.delivered_email
AND a.sent_gender = b.delivered_gender
AND a.sent_age = b.delivered_age
AND a.sent_n = b.delivered_n
FULL OUTER JOIN #email_blocked_agg AS c ON a.sent_email = c.blocked_email
AND a.sent_gender = c.blocked_gender
AND a.sent_age = c.blocked_age
AND a.sent_n = c.blocked_n
FULL OUTER JOIN #email_hardbounced_agg AS d ON a.sent_email = d.hardbounced_email
AND a.sent_gender = d.hardbounced_gender
AND a.sent_age = d.hardbounced_age
AND a.sent_n = d.hardbounced_n
FULL OUTER JOIN #email_opened_agg AS e ON a.sent_email = e.opened_email
AND a.sent_gender = e.opened_gender
AND a.sent_age = e.opened_age
AND b.delivered_n = e.opened_n
FULL OUTER JOIN #email_clicked_agg AS f ON a.sent_email = f.clicked_email
AND a.sent_gender = f.clicked_gender
AND a.sent_age = f.clicked_age
AND e.opened_n = f.clicked_n;


UPDATE #email_agg
SET sent_email = delivered_email,
    sent_age = delivered_age,
    sent_gender = delivered_gender
WHERE sent_email IS NULL;


UPDATE #email_agg
SET sent_email = blocked_email,
    sent_age = blocked_age,
    sent_gender = blocked_gender
WHERE sent_email IS NULL;


UPDATE #email_agg
SET sent_email = hardbounced_email,
    sent_age = hardbounced_age,
    sent_gender = hardbounced_gender
WHERE sent_email IS NULL;


UPDATE #email_agg
SET sent_email = opened_email,
    sent_age = opened_age,
    sent_gender = opened_gender
WHERE sent_email IS NULL;


UPDATE #email_agg
SET sent_email = clicked_email,
    sent_age = clicked_age,
    sent_gender = clicked_gender
WHERE sent_email IS NULL;


SELECT #email_agg.*,
       mktgemail.msdyncrm_name,
       mktgemail.createdon INTO email_agg
FROM #email_agg
LEFT JOIN msdyncrm_marketingemail AS mktgemail ON UPPER(#email_agg.sent_email) = mktgemail.Id;


DROP TABLE IF EXISTS email_agg_percent;


SELECT sent_email,
       SUM(sent_n) AS sent_sum,
       SUM(delivered_n) AS delivered_sum,
       SUM(opened_n) AS opened_sum,
       SUM(clicked_n) AS clicked_sum,
       SUM(blocked_n) AS blocked_sum,
       SUM(hardbounced_n) AS hardbounced_sum,
       msdyncrm_name,
       createdon INTO #email_agg_percent
FROM email_agg
GROUP BY sent_email,
         msdyncrm_name,
         createdon;


SELECT #email_agg_percent.*,
       (CAST(delivered_sum AS FLOAT)/CAST(sent_sum AS FLOAT))*100.0 AS delivered_percent,
       (CAST(opened_sum AS FLOAT)/CAST(delivered_sum AS FLOAT))*100.0 AS opened_percent,
       (CAST(clicked_sum AS FLOAT)/CAST(delivered_sum AS FLOAT))*100.0 AS clicked_percent INTO email_agg_percent
FROM #email_agg_percent;

END
