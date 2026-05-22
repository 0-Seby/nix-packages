import unittest
from pyfluids import HumidAir, InputHumidAir

class TestPyFluidsState(unittest.TestCase):

    humid_air_alt: HumidAir | None = None
    humid_air_press: HumidAir | None = None

    def setUp(self) -> None:
        """Set up two HumidAir states defined by identical physical locations
        but through different input paths (altitude vs direct pressure).
        """
        self.humid_air_alt = HumidAir().with_state(
            InputHumidAir.altitude(0),
            InputHumidAir.temperature(20),
            InputHumidAir.relative_humidity(50),
        )
        self.humid_air_press = HumidAir().with_state(
            InputHumidAir.pressure(101325),
            InputHumidAir.temperature(20),
            InputHumidAir.relative_humidity(50),
        )

    def test_input_equivalence(self) -> None:
        """Verify that 0 altitude matches sea-level atmospheric pressure."""
        self.assertEqual(
            InputHumidAir.altitude(0), 
            InputHumidAir.pressure(101325)
        )

    def test_physical_properties_match(self) -> None:
        """Verify that both calculation pathways yield identical density coordinates."""
        # Assert to type checkers that these are definitely not None here
        assert self.humid_air_alt is not None
        assert self.humid_air_press is not None
        
        self.assertEqual(
            self.humid_air_alt.density, 
            self.humid_air_press.density
        )

    def test_thermodynamic_outputs(self) -> None:
        """Sanity check a few distinct physical outputs to ensure CoolProp is executing."""
        assert self.humid_air_alt is not None
        
        self.assertAlmostEqual(self.humid_air_alt.density, 1.19935927, places=6)
        self.assertGreater(self.humid_air_alt.enthalpy, 0)
        self.assertLess(self.humid_air_alt.wet_bulb_temperature, self.humid_air_alt.temperature)

if __name__ == "__main__":
    unittest.main()
