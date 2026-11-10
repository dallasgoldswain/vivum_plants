-- Audit events are append-only: no updates, and deletes only once past retention (2 years).
CREATE OR REPLACE FUNCTION protect_audit_events()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    RAISE EXCEPTION 'audit_events are append-only';
  END IF;

  IF TG_OP = 'DELETE' AND OLD.created_at > now() - interval '2 years' THEN
    RAISE EXCEPTION 'audit_events can only be deleted after 2 years';
  END IF;

  RETURN OLD;
END;
$$;
