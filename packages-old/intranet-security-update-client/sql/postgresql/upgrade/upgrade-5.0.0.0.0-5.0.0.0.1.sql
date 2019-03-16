-- upgrade-5.0.0.0.0-5.0.0.0.1.sql

SELECT acs_log__debug('/packages/intranet-security-update-client/sql/postgresql/upgrade/upgrade-5.0.0.0.0-5.0.0.0.1.sql','');


-- Compatibility version of fill_holes:
-- Fills holes for 2012 - 2022.
create or replace function im_exchange_rate_fill_holes (varchar)
returns integer as $body$
DECLARE
    p_currency                  alias for $1;
    v_start_date                date;
    v_end_date                  date;
BEGIN
    RAISE NOTICE 'im_exchange_rate_fill_holes: cur=%', p_currency;

    v_start_date := to_date('2010-01-01', 'YYYY-MM-DD');
    v_end_date = v_start_date +'13 years'::interval;

    RETURN im_exchange_rate_fill_holes (p_currency, v_start_date, v_end_date);

end;$body$ language 'plpgsql';
