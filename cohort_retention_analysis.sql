
WITH users_clean AS (
    SELECT
        user_id,
        promo_signup_flag,

        CASE
            WHEN length(split_part(clean_date, '-', 3)) = 4 
                THEN to_timestamp(clean_date, 'DD-MM-YYYY')
            WHEN length(split_part(clean_date, '-', 3)) = 2 
                THEN to_timestamp(clean_date, 'DD-MM-YY')
        END AS signup_timestamp

    FROM (
        SELECT
            user_id,
            promo_signup_flag,
            replace(
                replace(split_part(signup_datetime, ' ', 1), '/', '-'),
                '.',
                '-'
            ) AS clean_date
        FROM cohort_users_raw
    ) a
),

events_clean AS (
    SELECT
        user_id,
        event_type,
        revenue,

        CASE
            WHEN length(split_part(clean_date, '-', 3)) = 4 
                THEN to_timestamp(clean_date, 'DD-MM-YYYY')
            WHEN length(split_part(clean_date, '-', 3)) = 2 
                THEN to_timestamp(clean_date, 'DD-MM-YY')
        END AS event_timestamp

    FROM (
        SELECT
            user_id,
            event_type,
            revenue,
            replace(
                replace(split_part(event_datetime, ' ', 1), '/', '-'),
                '.',
                '-'
            ) AS clean_date
        FROM cohort_events_raw
    ) a
)

SELECT
    u.promo_signup_flag,
    date_trunc('month', u.signup_timestamp)::date AS cohort_month,

    (
        date_part('year', age(
            date_trunc('month', e.event_timestamp),
            date_trunc('month', u.signup_timestamp)
        )) * 12
        +
        date_part('month', age(
            date_trunc('month', e.event_timestamp),
            date_trunc('month', u.signup_timestamp)
        ))
    ) AS month_offset,

    COUNT(DISTINCT u.user_id) AS users_total

FROM users_clean u
JOIN events_clean e
    ON u.user_id = e.user_id

WHERE
    e.event_timestamp IS NOT NULL
    AND u.signup_timestamp IS NOT NULL
    AND e.event_type IS NOT NULL
    AND e.event_type != 'test_event'
    AND date_trunc('month', e.event_timestamp)
        BETWEEN DATE '2025-01-01' AND DATE '2025-06-01'

GROUP BY
    u.promo_signup_flag,
    cohort_month,
    month_offset

ORDER BY
    u.promo_signup_flag,
    cohort_month,
    month_offset;