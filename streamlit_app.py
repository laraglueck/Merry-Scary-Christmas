import streamlit as st


st.set_page_config(
    page_title="Merry Scary Christmas",
    page_icon="🎄",
    layout="centered",
)

st.title("Merry Scary Christmas")
st.subheader("Can your team escape Santa Scare before midnight?")

st.write(
    "Three players enter Santa Scare's headquarters, restore the lights room by room, "
    "recover the stolen presents, and work together to reach the attic."
)

st.info(
    "Deployment setup is ready. The playable game is still being built; this page is "
    "a placeholder for the group project."
)

st.caption("Local co-op | one shared screen | a very quiet attic")
