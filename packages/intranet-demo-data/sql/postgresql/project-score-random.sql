

update im_projects
set project_budget = round(((random() * 100) ^2) / 1000) * 1000
where 1 = 1 and project_budget is null;


update im_projects
set project_budget_hours = project_budget / 50
where 1 = 1 and project_budget_hours is null;

update im_projects
set score_revenue = round(random() * 10)
where 1 = 1 and score_revenue is null;

update im_projects
set score_strategic = round(random() * 10)
where 1 = 1 and score_strategic is null;

update im_projects
set score_finance_roi = 6 + round(random() * 24)
where 1 = 1 and score_finance_roi is null;

update im_projects
set score_capabilities = round(random() * 10)
where 1 = 1 and score_capabilities is null;

update im_projects
set score_risk = round(random() * 10)
where 1 = 1 and score_risk is null;

update im_projects
set score_finance_npv = round(random() * 10)
where 1 = 1 and score_finance_npv is null;

update im_projects
set score_finance_cost = round(random() * 10)
where 1 = 1 and score_finance_cost is null;

update im_projects
set score_customers = round(random() * 10)
where 1 = 1 and score_customers is null;







