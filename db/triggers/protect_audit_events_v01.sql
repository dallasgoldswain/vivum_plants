CREATE TRIGGER protect_audit_events
BEFORE UPDATE OR DELETE ON audit_events
FOR EACH ROW EXECUTE FUNCTION protect_audit_events();
