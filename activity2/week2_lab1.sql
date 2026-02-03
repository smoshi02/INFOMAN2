--Activity 1
CREATE  OR REPLACE FUNCTION get_price_category(p_flight-id INT)
RETURN TEXT AS $$
DECLARE flight_duration INTERVAL;
BEGIN
        SELECT arrival_time - departure_time
        INTO flight_duration
        FROM flights
        WHERE flight_id = p_flight_id;
        RETURN flight_duration;
END;

$$ LANGUAGE plpgsql;


--Activty 2
CREATE OR REPLACE FUNCTION get_price_category(p_flight_id INT)
 RETURNS TEXT AS $$
DECLARE
	var_base_price NUMERIC;
BEGIN 
	SELECT base_price
	INTO var_base_price
	FROM flights
	WHERE flight_id = p_flight_id;
	 
	IF var_base_price < 300 THEN
		RETURN 'Budget';
	ELSIF var_base_price > 800 THEN
		RETURN 'Premium';
	ELSE
		RETURN 'Standard';
	END IF;
END;
$$ LANGUAGE plpgsql;

--Activity 3
CREATE OR REPLACE PROCEDURE book_flight(IN p_passenger_id INT, p_flight_id INT, p_seat_number VARCHAR)
AS $$
BEGIN
	INSERT INTO bookings(
		flight_id, 
		passenger_id, 
		booking_date, 
		seat_number, 
		status
	)
	VALUES(
		p_flight_id,
		p_passenger_id,
		CURRENT_DATE,
		p_seat_number,
		'Confirmed'
	);
	
END;
$$ LANGUAGE plpgsql;

--Activity 4
CREATE OR REPLACE PROCEDURE increase_prices_for_airline(p_airline_id INT, p_percentage_increase NUMERIC)
AS $$
DECLARE
	flight_rec RECORD;
BEGIN 
	FOR flight_rec IN SELECT flight_id, base_price
	FROM flights
	WHERE airline_id = p_airline_id

	LOOP 
		UPDATE flights
		SET base_price = flight_rec.base_price * (1 + p_percentage_increase / 100)
		WHERE flight_id = flight_rec.flight_id;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

