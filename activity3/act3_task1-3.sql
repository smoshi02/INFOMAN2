--Function Task 1

CREATE OR REPLACE FUNCTION log_product_changes()
RETURNS TRIGGER AS $$
BEGIN
	IF (TG_OP = 'INSERT') THEN
		INSERT INTO products_audit(product_id, change_type, new_name, new_price)
		VALUES(NEW.product_id, 'INSERT', NEW.name, NEW.price);
		RETURN NEW;
	ELSIF (TG_OP = 'DELETE') THEN
		INSERT INTO products_audit(product_id, change_type, old_name, old_price)
		VALUES(	OLD.product_id, 'DELETE', OLD.name, OLD.price);
		RETURN OLD;
	ELSIF (TG_OP = 'UPDATE') THEN
		IF NEW.name IS DISTINCT FROM OLD.name OR NEW.price IS DISTINCT FROM OLD.price THEN
		INSERT INTO products_audit(product_id, change_type, old_name, new_name, old_price, new_price)
		VALUES(NEW.product_id, 'UPDATE', OLD.name, NEW.name, OLD.price, NEW.price);

		END IF;
		RETURN NEW;

	END IF;
END;
$$ LANGUAGE plpgsql;


--Trigger Task 2

CREATE TRIGGER product_audit_trigger
AFTER INSERT or UPDATE or DELETE ON products
FOR EACH ROW
EXECUTE FUNCTION log_product_changes();

--Bonus Act

--Function
CREATE OR REPLACE FUNCTION set_last_modified()
RETURNS TRIGGER AS $$
BEGIN
	NEW.last_modified = NOW();
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--Trigger
CREATE TRIGGER set_last_modified_trigger
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION set_last_modified();
