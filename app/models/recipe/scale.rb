# Scales a recipe version to a target volume (SU03, D98). Each component is rounded to the
# nearest 50 mL, or 25 mL under 1 L, and the rounded total is shown, since it may differ
# from the target. Volume only: weight is never converted. The browser does the same sum
# (scale_controller.js) so it works offline; the tests hold both to this rule.
class Recipe::Scale
  Line = Data.define(:component, :millilitres)

  attr_reader :target_ml

  def initialize(version, target_ml)
    @version = version
    @target_ml = target_ml.to_d
  end

  def self.step_for(target_ml) = target_ml < 1000 ? 25 : 50

  def lines
    step = self.class.step_for(target_ml)
    @version.components.map do |component|
      Line.new(component, ((target_ml * @version.fraction_for(component)) / step).round * step)
    end
  end

  def total_ml = lines.sum(&:millilitres)
end
